import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";

// DELETE /api/habits/[id] — archive a habit (soft delete)
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;

  const habit = await db.habit.findFirst({ where: { id, userId } });
  if (!habit) return NextResponse.json({ error: "Not found" }, { status: 404 });

  await db.habit.update({ where: { id }, data: { archivedAt: new Date() } });
  return new NextResponse(null, { status: 204 });
}
