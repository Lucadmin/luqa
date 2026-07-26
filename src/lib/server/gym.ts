import type { Prisma } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import {
  best1RM,
  estimate1RM,
  exerciseKey,
  parseSetLine,
  topWeight,
  totalReps,
  totalVolume,
} from "@/lib/gym";
import type { ExerciseDTO, ExercisePointDTO, GymSetDTO } from "@/lib/types";
import { toDateKey } from "@/lib/life";

/** Everything a session DTO needs, in one include. */
export const sessionInclude = {
  exercises: {
    include: { exercise: true, sets: true },
    orderBy: { order: "asc" },
  },
} satisfies Prisma.GymSessionInclude;

/** One exercise as it arrives from the editor or the importer. */
export interface ExerciseInput {
  exerciseId?: string;
  name?: string;
  raw?: string;
  notes?: string;
}

/**
 * Maps exercise names onto ids, creating the ones that don't exist yet.
 * Matching ignores case and spacing so "Lat Pulldown" typed in a hurry as "lat
 * pulldown" lands on the row that already has five years of history.
 */
export async function resolveExerciseIds(
  userId: string,
  names: string[],
): Promise<Map<string, string>> {
  const existing = await db.exercise.findMany({
    where: { userId },
    select: { id: true, name: true },
  });

  const byKey = new Map(existing.map((e) => [exerciseKey(e.name), e.id]));

  // Dedupe first: two spellings in the same payload must not create two rows.
  const missing = new Map<string, string>();
  for (const name of names) {
    const key = exerciseKey(name);
    if (!key || byKey.has(key) || missing.has(key)) continue;
    missing.set(key, name.trim());
  }

  if (missing.size > 0) {
    await db.exercise.createMany({
      data: [...missing.values()].map((name) => ({ userId, name })),
      skipDuplicates: true,
    });

    const created = await db.exercise.findMany({
      where: { userId, name: { in: [...missing.values()] } },
      select: { id: true, name: true },
    });
    for (const e of created) byKey.set(exerciseKey(e.name), e.id);
  }

  return byKey;
}

/**
 * Replaces a session's exercises with `inputs`. Set lines are parsed here — the
 * one place it happens — so the editor and the importer can never disagree
 * about what a line means.
 */
export async function writeSessionExercises(
  tx: Prisma.TransactionClient,
  sessionId: string,
  inputs: ExerciseInput[],
  idByKey: Map<string, string>,
): Promise<void> {
  await tx.sessionExercise.deleteMany({ where: { sessionId } });

  for (const [index, input] of inputs.entries()) {
    const exerciseId =
      input.exerciseId ?? (input.name ? idByKey.get(exerciseKey(input.name)) : undefined);
    if (!exerciseId) continue;

    const raw = input.raw ?? "";
    const { sets } = parseSetLine(raw);

    await tx.sessionExercise.create({
      data: {
        sessionId,
        exerciseId,
        order: index,
        raw,
        notes: input.notes ?? "",
        sets: {
          create: sets.map((s, order) => ({
            order,
            weight: s.weight,
            reps: s.reps,
            note: s.note,
          })),
        },
      },
    });
  }
}

/** Ids of the exercises named or referenced by a payload, for the resolve step. */
export function namesToResolve(inputs: ExerciseInput[]): string[] {
  return inputs
    .filter((i) => !i.exerciseId && i.name)
    .map((i) => i.name as string);
}

/**
 * Verifies every referenced exercise id actually belongs to the user, so a
 * payload can't attach someone else's exercise to a session.
 */
export async function ownedExerciseIds(
  userId: string,
  ids: string[],
): Promise<Set<string>> {
  if (ids.length === 0) return new Set();
  const rows = await db.exercise.findMany({
    where: { userId, id: { in: ids } },
    select: { id: true },
  });
  return new Set(rows.map((r) => r.id));
}

// --- exercise stats ----------------------------------------------------------

interface ExerciseUsage {
  sessionCount: number;
  lastPerformed: string | null;
  locationIds: Set<string>;
  /** The set line and gym from the most recent time, for the editor's prefill. */
  lastRaw: string | null;
  lastLocationId: string | null;
  /** Sort key behind `lastRaw`: session date, then when it was written. */
  lastAt: [number, number];
}

/**
 * How often and where each exercise has been done. One query over the join
 * table; the numbers drive the picker's "last done" hints and decide whether an
 * exercise even needs a location filter.
 */
export async function exerciseUsage(
  userId: string,
): Promise<Map<string, ExerciseUsage>> {
  const rows = await db.sessionExercise.findMany({
    where: { session: { userId } },
    select: {
      exerciseId: true,
      raw: true,
      session: { select: { date: true, locationId: true, createdAt: true } },
    },
  });

  const usage = new Map<string, ExerciseUsage>();

  for (const row of rows) {
    let entry = usage.get(row.exerciseId);
    if (!entry) {
      entry = {
        sessionCount: 0,
        lastPerformed: null,
        locationIds: new Set(),
        lastRaw: null,
        lastLocationId: null,
        lastAt: [-Infinity, -Infinity],
      };
      usage.set(row.exerciseId, entry);
    }

    entry.sessionCount += 1;
    const dateKey = toDateKey(row.session.date);
    if (!entry.lastPerformed || dateKey > entry.lastPerformed) {
      entry.lastPerformed = dateKey;
    }

    // Two sessions can share a date, so createdAt breaks the tie.
    const at: [number, number] = [
      row.session.date.getTime(),
      row.session.createdAt.getTime(),
    ];
    if (at[0] > entry.lastAt[0] || (at[0] === entry.lastAt[0] && at[1] > entry.lastAt[1])) {
      entry.lastAt = at;
      entry.lastRaw = row.raw || null;
      entry.lastLocationId = row.session.locationId;
    }

    if (row.session.locationId) entry.locationIds.add(row.session.locationId);
  }

  return usage;
}

export function toExerciseDTO(
  exercise: { id: string; name: string; notes: string; archivedAt: Date | null },
  usage: Map<string, ExerciseUsage>,
): ExerciseDTO {
  const stats = usage.get(exercise.id);
  return {
    id: exercise.id,
    name: exercise.name,
    notes: exercise.notes,
    archived: exercise.archivedAt !== null,
    sessionCount: stats?.sessionCount ?? 0,
    lastPerformed: stats?.lastPerformed ?? null,
    locationIds: stats ? [...stats.locationIds] : [],
    lastRaw: stats?.lastRaw ?? null,
    lastLocationId: stats?.lastLocationId ?? null,
  };
}

/**
 * Every time an exercise was done, oldest first, with the derived numbers the
 * history sheet plots. `isPr` marks the sessions that beat everything before
 * them, which is the only badge worth showing on a graph.
 */
export function buildPoints(
  rows: {
    id: string;
    raw: string;
    notes: string;
    sets: { weight: number | null; reps: number | null; note: string | null; order: number }[];
    session: { id: string; date: Date; locationId: string | null };
  }[],
): ExercisePointDTO[] {
  const points = rows
    .map((row) => {
      const sets: GymSetDTO[] = [...row.sets]
        .sort((a, b) => a.order - b.order)
        .map((s) => ({ weight: s.weight, reps: s.reps, note: s.note }));

      return {
        sessionId: row.session.id,
        date: toDateKey(row.session.date),
        locationId: row.session.locationId,
        raw: row.raw,
        notes: row.notes,
        sets,
        topWeight: topWeight(sets),
        best1RM: best1RM(sets),
        totalReps: totalReps(sets),
        volume: totalVolume(sets),
        isPr: false,
      };
    })
    .sort((a, b) => (a.date < b.date ? -1 : a.date > b.date ? 1 : 0));

  let ceiling = 0;
  for (const point of points) {
    if (point.best1RM !== null && point.best1RM > ceiling) {
      // The first session on record isn't a personal record, it's a baseline.
      point.isPr = ceiling > 0;
      ceiling = point.best1RM;
    }
  }

  return points;
}

export { estimate1RM };
