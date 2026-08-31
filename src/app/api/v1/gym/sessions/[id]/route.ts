import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { toGymSessionDTO } from "@/lib/serializers";
import {
  namesToResolve,
  ownedExerciseIds,
  resolveExerciseIds,
  sessionInclude,
  writeSessionExercises,
} from "@/lib/server/gym";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { dateFromKey } from "@/lib/server/money";
import { updateGymSessionSchema } from "@/lib/validations";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const mobileSession = await authenticateMobileRequest(request);
    const { id } = await params;
    const session = await db.gymSession.findFirst({
      where: { id, userId: mobileSession.userId },
      include: sessionInclude,
    });
    if (!session) {
      return mobileJson(
        { error: { code: "not_found", message: "Workout not found" } },
        { status: 404 },
      );
    }
    return mobileJson({ session: toGymSessionDTO(session) });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}

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
  const existing = await db.gymSession.findFirst({
    where: { id, userId: mobileSession.userId },
    select: { id: true },
  });
  if (!existing) {
    return mobileJson(
      { error: { code: "not_found", message: "Workout not found" } },
      { status: 404 },
    );
  }

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = updateGymSessionSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const input = parsed.data;

  if (input.locationId) {
    const location = await db.gymLocation.findFirst({
      where: { id: input.locationId, userId: mobileSession.userId },
      select: { id: true },
    });
    if (!location) {
      return mobileJson(
        { error: { code: "unknown_gym", message: "Unknown gym" } },
        { status: 400 },
      );
    }
  }

  let idByKey = new Map<string, string>();
  if (input.exercises) {
    const referenced = input.exercises.flatMap((exercise) =>
      exercise.exerciseId ? [exercise.exerciseId] : [],
    );
    const owned = await ownedExerciseIds(mobileSession.userId, referenced);
    if (referenced.some((exerciseId) => !owned.has(exerciseId))) {
      return mobileJson(
        { error: { code: "unknown_exercise", message: "Unknown exercise" } },
        { status: 400 },
      );
    }
    idByKey = await resolveExerciseIds(
      mobileSession.userId,
      namesToResolve(input.exercises),
    );
  }

  const session = await db.$transaction(async (tx) => {
    await tx.gymSession.update({
      where: { id },
      data: {
        ...(input.date !== undefined
          ? { date: dateFromKey(input.date) }
          : {}),
        ...(input.locationId !== undefined
          ? { locationId: input.locationId ?? null }
          : {}),
        ...(input.notes !== undefined ? { notes: input.notes } : {}),
      },
    });
    if (input.exercises) {
      await writeSessionExercises(tx, id, input.exercises, idByKey);
    }
    return tx.gymSession.findUniqueOrThrow({
      where: { id },
      include: sessionInclude,
    });
  });
  return mobileJson({ session: toGymSessionDTO(session) });
}
