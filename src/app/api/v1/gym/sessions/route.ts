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
  canonicalExerciseIds,
  resolveExerciseIds,
  sessionInclude,
  writeSessionExercises,
} from "@/lib/server/gym";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { dateFromKey, todayKey } from "@/lib/server/money";
import { createGymSessionSchema } from "@/lib/validations";

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

export async function GET(request: Request) {
  try {
    const mobileSession = await authenticateMobileRequest(request);
    const url = new URL(request.url);
    const cursor = url.searchParams.get("cursor");
    const limit = Math.min(
      MAX_LIMIT,
      Math.max(1, Number(url.searchParams.get("limit")) || DEFAULT_LIMIT),
    );
    const rows = await db.gymSession.findMany({
      where: { userId: mobileSession.userId },
      orderBy: [{ date: "desc" }, { createdAt: "desc" }, { id: "desc" }],
      take: limit + 1,
      ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
      include: sessionInclude,
    });
    const hasMore = rows.length > limit;
    const page = hasMore ? rows.slice(0, limit) : rows;
    return mobileJson({
      sessions: page.map(toGymSessionDTO),
      nextCursor: hasMore ? page.at(-1)?.id ?? null : null,
    });
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
}

export async function POST(request: Request) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = createGymSessionSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const input = parsed.data;

  if (input.id) {
    // A device that never saw the response sends the same request again. It
    // must get the workout it already started, not a second empty one beside
    // it in the same day.
    const existing = await db.gymSession.findUnique({
      where: { id: input.id },
      include: sessionInclude,
    });
    if (existing) {
      if (existing.userId !== mobileSession.userId) {
        return mobileJson(
          { error: { code: "id_conflict", message: "That id is already in use" } },
          { status: 409 },
        );
      }
      return mobileJson({ session: toGymSessionDTO(existing) }, { status: 200 });
    }
  }

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

  const referenced = input.exercises.flatMap((exercise) =>
    exercise.exerciseId ? [exercise.exerciseId] : [],
  );
  const canonicalIds = await canonicalExerciseIds(
    mobileSession.userId,
    referenced,
  );
  if (referenced.some((id) => !canonicalIds.has(id))) {
    return mobileJson(
      { error: { code: "unknown_exercise", message: "Unknown exercise" } },
      { status: 400 },
    );
  }

  const idByKey = await resolveExerciseIds(
    mobileSession.userId,
    namesToResolve(input.exercises),
  );
  const session = await db.$transaction(async (tx) => {
    const created = await tx.gymSession.create({
      data: {
        ...(input.id ? { id: input.id } : {}),
        userId: mobileSession.userId,
        date: dateFromKey(input.date ?? todayKey()),
        locationId: input.locationId ?? null,
        notes: input.notes,
      },
    });
    await writeSessionExercises(
      tx,
      created.id,
      input.exercises,
      idByKey,
      canonicalIds,
    );
    return tx.gymSession.findUniqueOrThrow({
      where: { id: created.id },
      include: sessionInclude,
    });
  });
  return mobileJson({ session: toGymSessionDTO(session) }, { status: 201 });
}
