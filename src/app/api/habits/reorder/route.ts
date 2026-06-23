import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { reorderHabitsSchema } from "@/lib/validations";

// POST /api/habits/reorder — persist a new ordering of habit ids.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = reorderHabitsSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }

  const owned = await db.habit.findMany({
    where: { userId, id: { in: parsed.data.ids } },
    select: { id: true },
  });
  const ownedIds = new Set(owned.map((h) => h.id));

  await db.$transaction(
    parsed.data.ids
      .filter((id) => ownedIds.has(id))
      .map((id, order) => db.habit.update({ where: { id }, data: { order } })),
  );

  return NextResponse.json({ ok: true });
}
