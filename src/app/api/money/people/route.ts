import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toPersonDTO } from "@/lib/serializers";
import { createPersonSchema } from "@/lib/validations";
import { reviveDeletedPerson } from "@/lib/server/tombstones";

// GET /api/money/people — everyone, archived included, in display order.
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const people = await db.person.findMany({
    where: { userId },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
  });

  return NextResponse.json({ people: people.map(toPersonDTO) });
}

// POST /api/money/people — add someone to split with.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createPersonSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  const revived = await reviveDeletedPerson(userId, d.name);
  if (revived) return NextResponse.json({ person: revived }, { status: 201 });

  const taken = await db.person.findFirst({
    where: { userId, name: d.name },
    select: { id: true },
  });
  if (taken) {
    return NextResponse.json(
      { error: `You already have someone called ${d.name}` },
      { status: 409 },
    );
  }

  const count = await db.person.count({ where: { userId } });

  const person = await db.person.create({
    data: {
      userId,
      name: d.name,
      color: d.color ?? "#6366f1",
      emoji: d.emoji ?? null,
      defaultPercent: d.defaultPercent ?? null,
      order: count,
    },
  });

  return NextResponse.json({ person: toPersonDTO(person) }, { status: 201 });
}
