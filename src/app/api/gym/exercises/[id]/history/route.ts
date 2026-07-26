import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { buildPoints, exerciseUsage, toExerciseDTO } from "@/lib/server/gym";
import type { ExerciseHistoryDTO } from "@/lib/types";

const MAX_POINTS = 400;

// GET /api/gym/exercises/:id/history?locationId=…
//
// The location filter matters more than it looks: a stack marked 70 at one gym
// is nothing like a 70 at another, so comparing across gyms can be nonsense.
// Passing a gym narrows the history to it; omitting it shows everything.
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const exercise = await db.exercise.findFirst({ where: { id, userId } });
  if (!exercise) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const locationId = new URL(request.url).searchParams.get("locationId");

  const rows = await db.sessionExercise.findMany({
    where: {
      exerciseId: id,
      session: { userId, ...(locationId ? { locationId } : {}) },
    },
    orderBy: { session: { date: "desc" } },
    take: MAX_POINTS,
    select: {
      id: true,
      raw: true,
      notes: true,
      sets: {
        select: { weight: true, reps: true, note: true, order: true },
      },
      session: { select: { id: true, date: true, locationId: true } },
    },
  });

  const points = buildPoints(rows);
  const usage = await exerciseUsage(userId);

  const oneRepMaxes = points
    .map((p) => p.best1RM)
    .filter((v): v is number => v !== null);
  const weights = points
    .map((p) => p.topWeight)
    .filter((v): v is number => v !== null);

  const history: ExerciseHistoryDTO = {
    exercise: toExerciseDTO(exercise, usage),
    points,
    bestEver: oneRepMaxes.length > 0 ? Math.max(...oneRepMaxes) : null,
    heaviest: weights.length > 0 ? Math.max(...weights) : null,
  };

  return NextResponse.json({ history });
}
