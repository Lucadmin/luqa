import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGymSessionDTO } from "@/lib/serializers";
import { dateFromKey, todayKey } from "@/lib/server/money";
import {
  gymOverview,
  namesToResolve,
  ownedExerciseIds,
  resolveExerciseIds,
  sessionInclude,
  writeSessionExercises,
} from "@/lib/server/gym";
import { createGymSessionSchema } from "@/lib/validations";

const DEFAULT_LIMIT = 30;
const MAX_LIMIT = 200;

// GET /api/gym — the gym screen in one payload: gyms, the exercise vocabulary
// with its usage stats, and the most recent sessions.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const url = new URL(request.url);
  const limit = Math.min(
    MAX_LIMIT,
    Math.max(1, Number(url.searchParams.get("limit")) || DEFAULT_LIMIT),
  );

  const overview = await gymOverview(userId, limit);

  return NextResponse.json({ overview });
}

// POST /api/gym — start a session. Sending it empty is the normal path: the
// date and gym are picked, the exercises get filled in as they happen.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createGymSessionSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  if (d.locationId) {
    const owns = await db.gymLocation.findFirst({
      where: { id: d.locationId, userId },
      select: { id: true },
    });
    if (!owns) return NextResponse.json({ error: "Unknown gym" }, { status: 400 });
  }

  const referenced = d.exercises.flatMap((e) => (e.exerciseId ? [e.exerciseId] : []));
  const owned = await ownedExerciseIds(userId, referenced);
  if (referenced.some((id) => !owned.has(id))) {
    return NextResponse.json({ error: "Unknown exercise" }, { status: 400 });
  }

  const idByKey = await resolveExerciseIds(userId, namesToResolve(d.exercises));

  const session = await db.$transaction(async (tx) => {
    const created = await tx.gymSession.create({
      data: {
        userId,
        date: dateFromKey(d.date ?? todayKey()),
        locationId: d.locationId ?? null,
        notes: d.notes,
      },
    });

    await writeSessionExercises(tx, created.id, d.exercises, idByKey);

    return tx.gymSession.findUniqueOrThrow({
      where: { id: created.id },
      include: sessionInclude,
    });
  });

  return NextResponse.json({ session: toGymSessionDTO(session) }, { status: 201 });
}
