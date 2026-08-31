import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGroupDTO } from "@/lib/serializers";
import { createGroupSchema } from "@/lib/validations";
import { reviveDeletedGroup } from "@/lib/server/tombstones";

// GET /api/money/groups — the user's groups with their member ids.
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const groups = await db.personGroup.findMany({
    where: { userId },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
    include: { members: true },
  });

  return NextResponse.json({ groups: groups.map(toGroupDTO) });
}

// POST /api/money/groups — create a group from a set of people.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createGroupSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  const memberIds = [...new Set(d.memberIds)];
  if (memberIds.length > 0) {
    const owned = await db.person.count({
      where: { userId, id: { in: memberIds } },
    });
    if (owned !== memberIds.length) {
      return NextResponse.json({ error: "Unknown person" }, { status: 400 });
    }
  }

  const revived = await reviveDeletedGroup(userId, d.name);
  if (revived) return NextResponse.json({ group: revived }, { status: 201 });

  const taken = await db.personGroup.findFirst({
    where: { userId, name: d.name },
    select: { id: true },
  });
  if (taken) {
    return NextResponse.json(
      { error: `You already have a group called ${d.name}` },
      { status: 409 },
    );
  }

  const count = await db.personGroup.count({ where: { userId } });

  const group = await db.personGroup.create({
    data: {
      userId,
      name: d.name,
      color: d.color ?? "#6366f1",
      emoji: d.emoji ?? null,
      order: count,
      members: { create: memberIds.map((personId) => ({ personId })) },
    },
    include: { members: true },
  });

  return NextResponse.json({ group: toGroupDTO(group) }, { status: 201 });
}
