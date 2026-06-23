// Server-side resolution of habit progress for a given logical day.
//
// Canonical "did the day's goal get met" flag lives in HabitLog.completedAt.
// For TASK / COUNT / unlinked-TIME habits it's maintained by the log endpoint.
// For category-linked TIME habits there's usually no log to mutate, so progress
// is derived from the tracked time on the linked category and the day feed
// reconciles completedAt lazily.

import type { Habit, HabitLog } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import {
  type DayProgress,
  type HabitGoal,
  type HabitSchedule,
  goalFraction,
  isGoalMet,
  isPeriodSchedule,
  isScheduledOn,
  periodRange,
} from "@/lib/habits";
import { toHabitDTO } from "@/lib/serializers";
import type { HabitDayDTO } from "@/lib/types";

export function habitSchedule(h: Habit): HabitSchedule {
  return {
    scheduleType: h.scheduleType,
    weekdays: h.weekdays,
    weekInterval: h.weekInterval,
    intervalDays: h.intervalDays,
    timesPerPeriod: h.timesPerPeriod,
    anchorDate: h.anchorDate,
    dates: h.dates,
    excludedDates: h.excludedDates,
    createdAt: h.createdAt.toISOString(),
  };
}

export function habitGoal(h: Habit): HabitGoal {
  return {
    goalType: h.goalType,
    targetCount: h.targetCount,
    targetSeconds: h.targetSeconds,
  };
}

/**
 * UTC window for a logical day, bucketed by entry start time (mirrors the
 * reports route). Server runs UTC; this is exact for UTC users and a known
 * approximation otherwise.
 */
export function dayWindow(dateKey: string, dayStartHour: number): [Date, Date] {
  const start = new Date(`${dateKey}T00:00:00.000Z`);
  start.setUTCHours(dayStartHour, 0, 0, 0);
  const end = new Date(start.getTime() + 24 * 3_600_000);
  return [start, end];
}

/** Tracked seconds + running-start for a set of categories within a day. */
async function trackedByCategory(
  userId: string,
  categoryIds: string[],
  dateKey: string,
  dayStartHour: number,
): Promise<Map<string, { seconds: number; runningSince: Date | null }>> {
  const out = new Map<string, { seconds: number; runningSince: Date | null }>();
  if (categoryIds.length === 0) return out;

  const [start, end] = dayWindow(dateKey, dayStartHour);
  const entries = await db.timeEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      categoryId: { in: categoryIds },
      startTime: { gte: start, lt: end },
    },
  });

  const now = Date.now();
  for (const e of entries) {
    if (!e.categoryId) continue;
    const cur = out.get(e.categoryId) ?? { seconds: 0, runningSince: null };
    const endMs = e.endTime ? e.endTime.getTime() : now;
    cur.seconds += Math.max(0, Math.round((endMs - e.startTime.getTime()) / 1000));
    if (!e.endTime) cur.runningSince = e.startTime;
    out.set(e.categoryId, cur);
  }
  return out;
}

/** Resolve the raw progress (count/seconds/runningSince) for one habit. */
function rawProgress(
  h: Habit,
  log: HabitLog | undefined,
  tracked: Map<string, { seconds: number; runningSince: Date | null }>,
): { progress: DayProgress; runningSince: Date | null } {
  if (h.goalType === "TIME" && h.categoryId) {
    const t = tracked.get(h.categoryId);
    return {
      progress: { count: log?.count ?? 0, seconds: t?.seconds ?? 0 },
      runningSince: t?.runningSince ?? null,
    };
  }
  return {
    progress: { count: log?.count ?? 0, seconds: log?.seconds ?? 0 },
    runningSince: log?.runningSince ?? null,
  };
}

/** All habits scheduled on `dateKey`, with resolved progress for that day. */
export async function resolveHabitDay(
  userId: string,
  dateKey: string,
  dayStartHour: number,
  weekStartsOn: number,
): Promise<HabitDayDTO[]> {
  const habits = await db.habit.findMany({
    where: { userId, archivedAt: null },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
  });

  const scheduled = habits.filter((h) =>
    isScheduledOn(habitSchedule(h), dateKey, weekStartsOn),
  );
  if (scheduled.length === 0) return [];

  const ids = scheduled.map((h) => h.id);
  const dayLogs = await db.habitLog.findMany({
    where: { habitId: { in: ids }, date: dateKey },
  });
  const logByHabit = new Map(dayLogs.map((l) => [l.habitId, l]));

  const linkedCatIds = [
    ...new Set(
      scheduled
        .filter((h) => h.goalType === "TIME" && h.categoryId)
        .map((h) => h.categoryId as string),
    ),
  ];
  const tracked = await trackedByCategory(userId, linkedCatIds, dateKey, dayStartHour);

  // Period quotas: count completed days in each period schedule's window.
  const periodHabits = scheduled.filter((h) => isPeriodSchedule(h.scheduleType));
  const periodCount = new Map<string, number>();
  if (periodHabits.length > 0) {
    let minFrom = dateKey;
    let maxTo = dateKey;
    const ranges = new Map<string, { from: string; to: string }>();
    for (const h of periodHabits) {
      const r = periodRange(h.scheduleType, dateKey, weekStartsOn);
      ranges.set(h.id, r);
      if (r.from < minFrom) minFrom = r.from;
      if (r.to > maxTo) maxTo = r.to;
    }
    const logs = await db.habitLog.findMany({
      where: {
        habitId: { in: periodHabits.map((h) => h.id) },
        date: { gte: minFrom, lte: maxTo },
        completedAt: { not: null },
      },
      select: { habitId: true, date: true },
    });
    for (const h of periodHabits) {
      const r = ranges.get(h.id)!;
      periodCount.set(
        h.id,
        logs.filter((l) => l.habitId === h.id && l.date >= r.from && l.date <= r.to)
          .length,
      );
    }
  }

  const result: HabitDayDTO[] = [];
  for (const h of scheduled) {
    const log = logByHabit.get(h.id);
    const { progress, runningSince } = rawProgress(h, log, tracked);
    const done = isGoalMet(habitGoal(h), progress);

    // Reconcile completedAt for linked-TIME habits (no log mutation path).
    if (h.goalType === "TIME" && h.categoryId) {
      const wasComplete = !!log?.completedAt;
      if (done !== wasComplete) {
        await db.habitLog.upsert({
          where: { habitId_date: { habitId: h.id, date: dateKey } },
          create: {
            habitId: h.id,
            date: dateKey,
            completedAt: done ? new Date() : null,
          },
          update: { completedAt: done ? new Date() : null },
        });
        if (isPeriodSchedule(h.scheduleType)) {
          periodCount.set(h.id, (periodCount.get(h.id) ?? 0) + (done ? 1 : -1));
        }
      }
    }

    const isPeriod = isPeriodSchedule(h.scheduleType);
    result.push({
      ...toHabitDTO(h),
      count: progress.count,
      seconds: progress.seconds,
      runningSince: runningSince ? runningSince.toISOString() : null,
      done,
      periodDone: isPeriod ? (periodCount.get(h.id) ?? 0) : null,
      periodTarget: isPeriod ? h.timesPerPeriod : null,
    });
  }

  return result;
}

/** Resolve a single habit's day DTO (used after a log mutation). */
export async function resolveSingleHabitDay(
  userId: string,
  h: Habit,
  dateKey: string,
  dayStartHour: number,
  weekStartsOn: number,
): Promise<HabitDayDTO> {
  const log =
    (await db.habitLog.findUnique({
      where: { habitId_date: { habitId: h.id, date: dateKey } },
    })) ?? undefined;

  const tracked =
    h.goalType === "TIME" && h.categoryId
      ? await trackedByCategory(userId, [h.categoryId], dateKey, dayStartHour)
      : new Map<string, { seconds: number; runningSince: Date | null }>();

  const { progress, runningSince } = rawProgress(h, log, tracked);
  const done = isGoalMet(habitGoal(h), progress);

  if (h.goalType === "TIME" && h.categoryId && done !== !!log?.completedAt) {
    await db.habitLog.upsert({
      where: { habitId_date: { habitId: h.id, date: dateKey } },
      create: { habitId: h.id, date: dateKey, completedAt: done ? new Date() : null },
      update: { completedAt: done ? new Date() : null },
    });
  }

  let periodDone: number | null = null;
  let periodTarget: number | null = null;
  if (isPeriodSchedule(h.scheduleType)) {
    const r = periodRange(h.scheduleType, dateKey, weekStartsOn);
    periodDone = await db.habitLog.count({
      where: { habitId: h.id, date: { gte: r.from, lte: r.to }, completedAt: { not: null } },
    });
    periodTarget = h.timesPerPeriod;
  }

  return {
    ...toHabitDTO(h),
    count: progress.count,
    seconds: progress.seconds,
    runningSince: runningSince ? runningSince.toISOString() : null,
    done,
    periodDone,
    periodTarget,
  };
}

/** Goal fraction (0..1) for a habit/log/tracked triple — used by stats. */
export function dayFraction(
  h: Habit,
  log: HabitLog | undefined,
  tracked: Map<string, { seconds: number; runningSince: Date | null }>,
): number {
  const { progress } = rawProgress(h, log, tracked);
  return goalFraction(habitGoal(h), progress);
}
