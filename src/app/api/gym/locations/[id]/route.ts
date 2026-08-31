import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGymLocationDTO } from "@/lib/serializers";
import { updateGymLocationSchema } from "@/lib/validations";

// PATCH /api/gym/locations/:id
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const location = await db.gymLocation.findFirst({ where: { id, userId } });
  if (!location) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateGymLocationSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  if (d.code && d.code !== location.code) {
    const clash = await db.gymLocation.findFirst({
      where: { userId, code: d.code, id: { not: id } },
      select: { id: true },
    });
    if (clash) {
      return NextResponse.json({ error: "That code is already taken" }, { status: 409 });
    }
  }

  const updated = await db.gymLocation.update({
    where: { id },
    data: {
      ...(d.code !== undefined ? { code: d.code } : {}),
      ...(d.name !== undefined ? { name: d.name } : {}),
      ...(d.color !== undefined ? { color: d.color } : {}),
      ...(d.order !== undefined ? { order: d.order } : {}),
      ...(d.archived !== undefined
        ? { archivedAt: d.archived ? new Date() : null }
        : {}),
    },
  });

  return NextResponse.json({ location: toGymLocationDTO(updated) });
}

// DELETE /api/gym/locations/:id — a gym with sessions behind it is archived
// instead, so those sessions don't silently lose where they happened.
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const location = await db.gymLocation.findFirst({ where: { id, userId } });
  if (!location) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const used = await db.gymSession.count({ where: { locationId: id } });
  if (used > 0) {
    await db.gymLocation.update({ where: { id }, data: { archivedAt: new Date() } });
    return NextResponse.json({ deleted: false, archived: true });
  }

  await db.gymLocation.update({
    where: { id },
    data: { deletedAt: new Date() },
  });
  return NextResponse.json({ deleted: true, archived: false });
}
