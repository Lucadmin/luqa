import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGroupDTO } from "@/lib/serializers";
import { updateGroupSchema } from "@/lib/validations";

// PATCH /api/money/groups/[id] — rename, restyle, change membership, archive.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const existing = await db.personGroup.findFirst({ where: { id, userId } });
  if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateGroupSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  if (d.name !== undefined && d.name !== existing.name) {
    const taken = await db.personGroup.findFirst({
      where: { userId, name: d.name, id: { not: id } },
      select: { id: true },
    });
    if (taken) {
      return NextResponse.json(
        { error: `You already have a group called ${d.name}` },
        { status: 409 },
      );
    }
  }

  let memberIds: string[] | null = null;
  if (d.memberIds !== undefined) {
    memberIds = [...new Set(d.memberIds)];
    if (memberIds.length > 0) {
      const owned = await db.person.count({
        where: { userId, id: { in: memberIds } },
      });
      if (owned !== memberIds.length) {
        return NextResponse.json({ error: "Unknown person" }, { status: 400 });
      }
    }
  }

  const group = await db.personGroup.update({
    where: { id },
    data: {
      ...(d.name !== undefined ? { name: d.name } : {}),
      ...(d.color !== undefined ? { color: d.color } : {}),
      ...(d.emoji !== undefined ? { emoji: d.emoji ?? null } : {}),
      ...(d.order !== undefined ? { order: d.order } : {}),
      ...(d.archived !== undefined
        ? { archivedAt: d.archived ? new Date() : null }
        : {}),
      // Membership is replaced wholesale — the editor always sends the full set.
      ...(memberIds
        ? {
            members: {
              deleteMany: {},
              create: memberIds.map((personId) => ({ personId })),
            },
          }
        : {}),
    },
    include: { members: true },
  });

  return NextResponse.json({ group: toGroupDTO(group) });
}

// DELETE /api/money/groups/[id] — remove a group. Past expenses keep their
// people and amounts; they simply lose the group label.
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const group = await db.personGroup.findFirst({ where: { id, userId } });
  if (!group) return NextResponse.json({ error: "Not found" }, { status: 404 });

  await db.personGroup.update({
    where: { id },
    data: { deletedAt: new Date() },
  });
  return new NextResponse(null, { status: 204 });
}
