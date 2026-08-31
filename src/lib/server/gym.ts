import type { Prisma } from "@/generated/prisma/client";
import { type DbTransaction, db } from "@/lib/db";
import {
  best1RM,
  estimate1RM,
  exerciseKey,
  formatSetLine,
  topWeight,
  totalReps,
  totalVolume,
} from "@/lib/gym";
import { toGymLocationDTO, toGymSessionDTO } from "@/lib/serializers";
import type {
  ExerciseDTO,
  ExerciseHistoryDTO,
  ExercisePointDTO,
  GymExerciseReferenceDTO,
  GymOverviewDTO,
  GymSetDTO,
} from "@/lib/types";
import { toDateKey } from "@/lib/life";
import { reviveExercises } from "@/lib/server/tombstones";

/** Everything a session DTO needs, in one include. */
export const sessionInclude = {
  exercises: {
    include: { exercise: true, sets: true },
    orderBy: { order: "asc" },
  },
} satisfies Prisma.GymSessionInclude;

/** One structured set as entered through the weight/reps inputs. */
export interface SetInput {
  weight?: number | null;
  reps?: number | null;
  note?: string | null;
}

/** One exercise as it arrives from the editor. */
export interface ExerciseInput {
  exerciseId?: string;
  name?: string;
  sets?: SetInput[];
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
  // Anything deleted whose name is being used again comes back first, so the
  // pass below finds it rather than colliding with it on the unique key.
  await reviveExercises(userId, names.map((name) => name.trim()));

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
 * Replaces a session's exercises with `inputs`. `raw` — the display line shown
 * in history and "last time" hints — is derived from the structured sets here,
 * the one place it happens, so it always reads the way the editor wrote it.
 */
export async function writeSessionExercises(
  tx: DbTransaction,
  sessionId: string,
  inputs: ExerciseInput[],
  idByKey: Map<string, string>,
): Promise<void> {
  await tx.sessionExercise.deleteMany({ where: { sessionId } });

  for (const [index, input] of inputs.entries()) {
    const exerciseId =
      input.exerciseId ?? (input.name ? idByKey.get(exerciseKey(input.name)) : undefined);
    if (!exerciseId) continue;

    // Drop rows the user added but never filled in — an empty set carries no
    // information and shouldn't get written just because a row existed.
    const sets = (input.sets ?? []).filter(
      (s) => s.weight != null || s.reps != null || (s.note && s.note.trim()),
    );

    await tx.sessionExercise.create({
      data: {
        sessionId,
        exerciseId,
        order: index,
        raw: formatSetLine(sets.map((s) => ({ weight: s.weight ?? null, reps: s.reps ?? null, note: s.note ?? null }))),
        notes: input.notes ?? "",
        sets: {
          create: sets.map((s, order) => ({
            order,
            weight: s.weight ?? null,
            reps: s.reps ?? null,
            note: s.note ?? null,
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
 * One true latest performance per exercise and location. The overview uses
 * this for selected-gym search ordering and placeholders; it deliberately
 * does not reuse the global `lastRaw` convenience field.
 */
export async function recentExerciseReferences(
  userId: string,
): Promise<GymExerciseReferenceDTO[]> {
  const rows = await db.sessionExercise.findMany({
    where: { session: { userId } },
    select: {
      exerciseId: true,
      raw: true,
      notes: true,
      sets: {
        orderBy: { order: "asc" },
        select: { weight: true, reps: true, note: true },
      },
      session: {
        select: {
          id: true,
          date: true,
          locationId: true,
          createdAt: true,
        },
      },
    },
  });

  rows.sort((left, right) => {
    const byDate = right.session.date.getTime() - left.session.date.getTime();
    if (byDate !== 0) return byDate;
    return right.session.createdAt.getTime() - left.session.createdAt.getTime();
  });

  const seen = new Set<string>();
  const references: GymExerciseReferenceDTO[] = [];
  for (const row of rows) {
    const key = `${row.exerciseId}:${row.session.locationId ?? "none"}`;
    if (!seen.add(key)) continue;
    references.push({
      exerciseId: row.exerciseId,
      sessionId: row.session.id,
      date: toDateKey(row.session.date),
      locationId: row.session.locationId,
      raw: row.raw,
      notes: row.notes,
      sets: row.sets,
    });
  }
  return references;
}

/** Shared browser/native overview query. */
export async function gymOverview(
  userId: string,
  limit: number,
): Promise<GymOverviewDTO> {
  const [locations, exercises, sessions, totalSessions, usage, references] =
    await Promise.all([
      db.gymLocation.findMany({
        where: { userId },
        orderBy: [{ order: "asc" }, { code: "asc" }],
      }),
      db.exercise.findMany({ where: { userId }, orderBy: { name: "asc" } }),
      db.gymSession.findMany({
        where: { userId },
        orderBy: [{ date: "desc" }, { createdAt: "desc" }],
        take: limit,
        include: sessionInclude,
      }),
      db.gymSession.count({ where: { userId } }),
      exerciseUsage(userId),
      recentExerciseReferences(userId),
    ]);

  return {
    locations: locations.map(toGymLocationDTO),
    exercises: exercises.map((exercise) => toExerciseDTO(exercise, usage)),
    recentReferences: references,
    sessions: sessions.map(toGymSessionDTO),
    totalSessions,
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

/**
 * Location-scoped exercise history. `beforeSessionId` makes "last time" mean
 * the workout before the one being edited, including for historical sessions.
 */
export async function exerciseHistory(
  userId: string,
  exerciseId: string,
  options: { locationId?: string | null; beforeSessionId?: string | null } = {},
): Promise<ExerciseHistoryDTO | null> {
  const exercise = await db.exercise.findFirst({
    where: { id: exerciseId, userId },
  });
  if (!exercise) return null;

  const before = options.beforeSessionId
    ? await db.gymSession.findFirst({
        where: { id: options.beforeSessionId, userId },
        select: { date: true, createdAt: true },
      })
    : null;

  const rows = await db.sessionExercise.findMany({
    where: {
      exerciseId,
      session: {
        userId,
        ...(options.locationId ? { locationId: options.locationId } : {}),
        ...(before
          ? {
              OR: [
                { date: { lt: before.date } },
                { date: before.date, createdAt: { lt: before.createdAt } },
              ],
            }
          : {}),
      },
    },
    orderBy: { session: { date: "desc" } },
    take: 400,
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
    .map((point) => point.best1RM)
    .filter((value): value is number => value !== null);
  const weights = points
    .map((point) => point.topWeight)
    .filter((value): value is number => value !== null);

  return {
    exercise: toExerciseDTO(exercise, usage),
    points,
    bestEver: oneRepMaxes.length > 0 ? Math.max(...oneRepMaxes) : null,
    heaviest: weights.length > 0 ? Math.max(...weights) : null,
  };
}

export { estimate1RM };
