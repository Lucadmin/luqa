import { db } from "@/lib/db";
import { exerciseKey } from "@/lib/gym";
import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { exerciseUsage, mergeExercises, toExerciseDTO } from "@/lib/server/gym";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { reviveExercises } from "@/lib/server/tombstones";
import { updateExerciseSchema } from "@/lib/validations";

async function ownedExercise(userId: string, id: string) {
  return db.exercise.findFirst({ where: { id, userId } });
}

// Renaming onto a name that already exists merges the two rather than
// failing. That is the whole point: years of logging leave "Lat Pulldown",
// "Lat Puldown" and "Latzug" as three separate histories, and merging them is
// how the graph becomes truthful again.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  const { id } = await params;
  const exercise = await ownedExercise(mobileSession.userId, id);
  if (!exercise) {
    return mobileJson(
      { error: { code: "not_found", message: "Exercise not found" } },
      { status: 404 },
    );
  }

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = updateExerciseSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const input = parsed.data;

  if (input.name && exerciseKey(input.name) !== exerciseKey(exercise.name)) {
    // A deleted exercise still holds its name on the unique key, so renaming
    // onto one would fail against a row nobody can see. Bringing it back
    // first turns that into the ordinary clash below, which merges.
    await reviveExercises(mobileSession.userId, [input.name]);

    const clash = (
      await db.exercise.findMany({
        where: { userId: mobileSession.userId },
        select: { id: true, name: true },
      })
    ).find(
      (other) =>
        other.id !== id && exerciseKey(other.name) === exerciseKey(input.name!),
    );

    if (clash) {
      const merged = await mergeExercises(mobileSession.userId, id, clash.id);
      if (!merged) {
        return mobileJson(
          { error: { code: "not_found", message: "Exercise not found" } },
          { status: 404 },
        );
      }
      return mobileJson({ exercise: merged.exercise, mergedInto: clash.id });
    }
  }

  const updated = await db.exercise.update({
    where: { id },
    data: {
      ...(input.name !== undefined ? { name: input.name } : {}),
      ...(input.notes !== undefined ? { notes: input.notes } : {}),
      ...(input.archived !== undefined
        ? { archivedAt: input.archived ? new Date() : null }
        : {}),
    },
  });

  const usage = await exerciseUsage(mobileSession.userId);
  return mobileJson({
    exercise: toExerciseDTO(updated, usage),
    mergedInto: null,
  });
}

// Only when nothing has been logged against it. An exercise with history gets
// archived instead, so old workouts keep reading the way they were written.
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  const { id } = await params;
  const exercise = await ownedExercise(mobileSession.userId, id);
  if (!exercise) {
    return mobileJson(
      { error: { code: "not_found", message: "Exercise not found" } },
      { status: 404 },
    );
  }

  const used = await db.sessionExercise.count({
    where: { exerciseId: id, session: { userId: mobileSession.userId } },
  });
  if (used > 0) {
    await db.exercise.update({
      where: { id },
      data: { archivedAt: new Date() },
    });
    return mobileJson({ deleted: false, archived: true });
  }

  await db.exercise.update({ where: { id }, data: { deletedAt: new Date() } });
  return mobileJson({ deleted: true, archived: false });
}
