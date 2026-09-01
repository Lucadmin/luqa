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
  addDays,
  type DayProgress,
  type HabitGoal,
  type HabitSchedule,
  goalFraction,
  isGoalMet,
  isPeriodSchedule,
  isScheduledOn,
  periodRange,
  rollingLookbackDays,
} from "@/lib/habits";
import type { HabitGoalPeriod } from "@/lib/types";
import { toHabitDTO } from "@/lib/serializers";
import type { HabitDayDTO } from "@/lib/types";

export function habitSchedule(h: Habit): HabitSchedule {
  return {
    scheduleType: h.scheduleType,
    weekdays: h.weekdays,
    weekInterval: h.weekInterval,
    intervalDays: h.intervalDays,
    intervalFromLastDone: h.intervalFromLastDone,
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
    goalPeriod: h.goalPeriod,
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

/** Map a TIME goal period to a schedule type for periodRange(). */
function goalPeriodToScheduleType(period: HabitGoalPeriod) {
  return period === "MONTH" ? "TIMES_PER_MONTH" : "TIMES_PER_WEEK";
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

  for (const e of entries) {
    if (!e.categoryId) continue;
    const cur = out.get(e.categoryId) ?? { seconds: 0, runningSince: null };
    if (e.endTime) {
      cur.seconds += Math.max(0, Math.round((e.endTime.getTime() - e.startTime.getTime()) / 1000));
    } else {
      // Running entry: record runningSince so the client adds live elapsed (avoids double-counting).
      cur.runningSince = e.startTime;
    }
    out.set(e.categoryId, cur);
  }
  return out;
}

/** Tracked seconds for a set of categories within a date range (for period-TIME goals). */
async function trackedByCategoryRange(
  userId: string,
  categoryIds: string[],
  from: string,
  to: string,
  dayStartHour: number,
): Promise<Map<string, number>> {
  const out = new Map<string, number>();
  if (categoryIds.length === 0) return out;

  const [startDate] = dayWindow(from, dayStartHour);
  const [, periodEnd] = dayWindow(to, dayStartHour);
  const entries = await db.timeEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      categoryId: { in: categoryIds },
      startTime: { gte: startDate, lt: periodEnd },
      endTime: { not: null },
    },
  });

  const now = Date.now();
  for (const e of entries) {
    if (!e.categoryId || !e.endTime) continue;
    const cur = out.get(e.categoryId) ?? 0;
    out.set(e.categoryId, cur + Math.max(0, Math.round((e.endTime.getTime() - e.startTime.getTime()) / 1000)));
  }
  // Also include any currently-running entry in the period
  const running = await db.timeEntry.findFirst({
    where: { userId, deletedAt: null, categoryId: { in: categoryIds }, startTime: { gte: startDate, lt: periodEnd }, endTime: null },
    orderBy: { startTime: "desc" },
  });
  if (running?.categoryId) {
    const cur = out.get(running.categoryId) ?? 0;
    out.set(running.categoryId, cur + Math.max(0, Math.round((now - running.startTime.getTime()) / 1000)));
  }
  return out;
}

/** Sum HabitLog.seconds across a date range for unlinked period-TIME habits. */
async function periodLogSeconds(
  habitIds: string[],
  from: string,
  to: string,
): Promise<Map<string, { seconds: number; runningSince: Date | null }>> {
  const out = new Map<string, { seconds: number; runningSince: Date | null }>();
  if (habitIds.length === 0) return out;

  const logs = await db.habitLog.findMany({
    where: { habitId: { in: habitIds }, date: { gte: from, lte: to } },
    select: { habitId: true, seconds: true, runningSince: true },
  });
  for (const l of logs) {
    const cur = out.get(l.habitId) ?? { seconds: 0, runningSince: null };
    cur.seconds += l.seconds;
    // Take the most recent runningSince (only today's log can have it running)
    if (l.runningSince && (!cur.runningSince || l.runningSince > cur.runningSince)) {
      cur.runningSince = l.runningSince;
    }
    out.set(l.habitId, cur);
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

/**
 * "Was this habit's goal met on this day", for the habits that need to know.
 *
 * Only a rolling interval does, and only for the days inside its own interval
 * — so this loads that window and nothing more. A habit not done in a year
 * costs the same query as one done yesterday.
 */
async function rollingHistory(
  habits: Habit[],
  dateKey: string,
): Promise<Map<string, Set<string>>> {
  const rolling = habits.filter((h) => rollingLookbackDays(habitSchedule(h)) > 0);
  const byHabit = new Map<string, Set<string>>();
  if (rolling.length === 0) return byHabit;

  const lookback = Math.max(
    ...rolling.map((h) => rollingLookbackDays(habitSchedule(h))),
  );
  const from = addDays(dateKey, -lookback);

  const logs = await db.habitLog.findMany({
    where: {
      habitId: { in: rolling.map((h) => h.id) },
      date: { gte: from, lte: dateKey },
      completedAt: { not: null },
    },
    select: { habitId: true, date: true },
  });
  for (const log of logs) {
    const days = byHabit.get(log.habitId) ?? new Set<string>();
    days.add(log.date);
    byHabit.set(log.habitId, days);
  }
  return byHabit;
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

  // A rolling interval is defined by when it was last done, so what it has
  // done has to be known before it can be asked whether it is due.
  const history = await rollingHistory(habits, dateKey);
  const scheduled = habits.filter((h) =>
    isScheduledOn(habitSchedule(h), dateKey, weekStartsOn, (day) =>
      history.get(h.id)?.has(day) ?? false,
    ),
  );
  if (scheduled.length === 0) return [];

  const ids = scheduled.map((h) => h.id);
  const dayLogs = await db.habitLog.findMany({
    where: { habitId: { in: ids }, date: dateKey },
  });
  const logByHabit = new Map(dayLogs.map((l) => [l.habitId, l]));

  // Separate period-TIME habits from daily-TIME habits.
  const periodTimeHabits = scheduled.filter(
    (h) => h.goalType === "TIME" && h.goalPeriod !== "DAY",
  );
  const dailyTimeHabits = scheduled.filter(
    (h) => h.goalType !== "TIME" || h.goalPeriod === "DAY",
  );

  // For daily TIME habits: track today's seconds by category.
  const dailyLinkedCatIds = [
    ...new Set(
      dailyTimeHabits
        .filter((h) => h.goalType === "TIME" && h.categoryId)
        .map((h) => h.categoryId as string),
    ),
  ];
  const tracked = await trackedByCategory(userId, dailyLinkedCatIds, dateKey, dayStartHour);

  // For period-TIME habits: aggregate seconds across the period window.
  const periodTrackedByCategory = new Map<string, number>();
  const periodLogSecondsMap = new Map<string, { seconds: number; runningSince: Date | null }>();

  if (periodTimeHabits.length > 0) {
    // Compute per-habit period windows (may differ by goalPeriod type).
    const habitPeriodRanges = new Map<string, { from: string; to: string }>();
    for (const h of periodTimeHabits) {
      const r = periodRange(goalPeriodToScheduleType(h.goalPeriod), dateKey, weekStartsOn);
      habitPeriodRanges.set(h.id, r);
    }
    // Linked period-TIME: fetch time entries across each period.
    const periodLinkedCatIds = [
      ...new Set(
        periodTimeHabits
          .filter((h) => h.categoryId)
          .map((h) => h.categoryId as string),
      ),
    ];
    if (periodLinkedCatIds.length > 0) {
      // Use the broadest range that covers all period windows.
      const allFroms = [...habitPeriodRanges.values()].map((r) => r.from);
      const allTos = [...habitPeriodRanges.values()].map((r) => r.to);
      const minFrom = allFroms.reduce((a, b) => (a < b ? a : b));
      const maxTo = allTos.reduce((a, b) => (a > b ? a : b));
      const catSecs = await trackedByCategoryRange(userId, periodLinkedCatIds, minFrom, maxTo, dayStartHour);
      catSecs.forEach((secs, catId) => periodTrackedByCategory.set(catId, secs));
    }
    // Unlinked period-TIME: sum HabitLog.seconds across the period.
    const unlinkedPeriodHabitIds = periodTimeHabits
      .filter((h) => !h.categoryId)
      .map((h) => h.id);
    if (unlinkedPeriodHabitIds.length > 0) {
      const allFroms = unlinkedPeriodHabitIds.map((id) => habitPeriodRanges.get(id)!.from);
      const allTos = unlinkedPeriodHabitIds.map((id) => habitPeriodRanges.get(id)!.to);
      const minFrom = allFroms.reduce((a, b) => (a < b ? a : b));
      const maxTo = allTos.reduce((a, b) => (a > b ? a : b));
      const logSecs = await periodLogSeconds(unlinkedPeriodHabitIds, minFrom, maxTo);
      logSecs.forEach((val, id) => periodLogSecondsMap.set(id, val));
    }
  }

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

    let progress: DayProgress;
    let runningSince: Date | null;

    if (h.goalType === "TIME" && h.goalPeriod !== "DAY") {
      // Period-TIME: use aggregated period seconds.
      if (h.categoryId) {
        const secs = periodTrackedByCategory.get(h.categoryId) ?? 0;
        progress = { count: 0, seconds: secs };
        runningSince = null; // running detection included in secs above
      } else {
        const periodData = periodLogSecondsMap.get(h.id) ?? { seconds: 0, runningSince: null };
        progress = { count: 0, seconds: periodData.seconds };
        runningSince = periodData.runningSince;
      }
    } else {
      const raw = rawProgress(h, log, tracked);
      progress = raw.progress;
      runningSince = raw.runningSince;
    }

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

  let progress: DayProgress;
  let runningSince: Date | null;

  if (h.goalType === "TIME" && h.goalPeriod !== "DAY") {
    const r = periodRange(goalPeriodToScheduleType(h.goalPeriod), dateKey, weekStartsOn);
    if (h.categoryId) {
      const catSecs = await trackedByCategoryRange(userId, [h.categoryId], r.from, r.to, dayStartHour);
      progress = { count: 0, seconds: catSecs.get(h.categoryId) ?? 0 };
      runningSince = null;
    } else {
      const logSecs = await periodLogSeconds([h.id], r.from, r.to);
      const periodData = logSecs.get(h.id) ?? { seconds: 0, runningSince: null };
      progress = { count: 0, seconds: periodData.seconds };
      runningSince = periodData.runningSince;
    }
  } else {
    const tracked =
      h.goalType === "TIME" && h.categoryId
        ? await trackedByCategory(userId, [h.categoryId], dateKey, dayStartHour)
        : new Map<string, { seconds: number; runningSince: Date | null }>();
    const raw = rawProgress(h, log, tracked);
    progress = raw.progress;
    runningSince = raw.runningSince;
  }

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
