import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { exerciseKey } from "@/lib/gym";
import { exerciseUsage, toExerciseDTO } from "@/lib/server/gym";
import { updateExerciseSchema } from "@/lib/validations";

// PATCH /api/gym/exercises/:id — rename, annotate, archive.
//
// Renaming onto a name that already exists merges the two rather than failing.
// That is the whole point: years of logging leave "Lat Pulldown", "Lat
// Puldown" and "Latzug" as three separate histories, and merging them is how
// the graph becomes truthful again.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const exercise = await db.exercise.findFirst({ where: { id, userId } });
  if (!exercise) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateExerciseSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  if (d.name && exerciseKey(d.name) !== exerciseKey(exercise.name)) {
    const clash = (
      await db.exercise.findMany({ where: { userId }, select: { id: true, name: true } })
    ).find((e) => e.id !== id && exerciseKey(e.name) === exerciseKey(d.name as string));

    if (clash) {
      await db.$transaction([
        db.sessionExercise.updateMany({
          where: { exerciseId: id },
          data: { exerciseId: clash.id },
        }),
        db.exercise.delete({ where: { id } }),
      ]);

      const usage = await exerciseUsage(userId);
      const merged = await db.exercise.findUniqueOrThrow({ where: { id: clash.id } });
      return NextResponse.json({
        exercise: toExerciseDTO(merged, usage),
        mergedInto: clash.id,
      });
    }
  }

  const updated = await db.exercise.update({
    where: { id },
    data: {
      ...(d.name !== undefined ? { name: d.name } : {}),
      ...(d.notes !== undefined ? { notes: d.notes } : {}),
      ...(d.archived !== undefined
        ? { archivedAt: d.archived ? new Date() : null }
        : {}),
    },
  });

  const usage = await exerciseUsage(userId);
  return NextResponse.json({ exercise: toExerciseDTO(updated, usage), mergedInto: null });
}

// DELETE /api/gym/exercises/:id — only when nothing has been logged against it.
// An exercise with history gets archived instead, so old sessions keep reading
// the way they were written.
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const exercise = await db.exercise.findFirst({ where: { id, userId } });
  if (!exercise) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const used = await db.sessionExercise.count({ where: { exerciseId: id } });
  if (used > 0) {
    await db.exercise.update({ where: { id }, data: { archivedAt: new Date() } });
    return NextResponse.json({ deleted: false, archived: true });
  }

  await db.exercise.delete({ where: { id } });
  return NextResponse.json({ deleted: true, archived: false });
}
