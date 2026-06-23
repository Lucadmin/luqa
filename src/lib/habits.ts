// Habit scheduling + goal logic. Pure functions, safe on client and server.
//
// All dates here are "date keys" — "YYYY-MM-DD" strings for a logical day in
// the user's timezone. Parsing builds a local midnight Date and only ever reads
// calendar fields (getFullYear/Month/Date/Day), so the math is timezone-stable.

import { isoDateKey } from "./time";
import type { HabitGoalPeriod, HabitGoalType, HabitScheduleType } from "./types";

export type { HabitGoalPeriod, HabitGoalType, HabitScheduleType };

export const PERIOD_SCHEDULES: HabitScheduleType[] = [
  "TIMES_PER_WEEK",
  "TIMES_PER_MONTH",
  "TIMES_PER_YEAR",
];

/** The subset of a habit needed to decide scheduling. */
export interface HabitSchedule {
  scheduleType: HabitScheduleType;
  weekdays: number[];
  weekInterval: number;
  intervalDays: number;
  timesPerPeriod: number;
  anchorDate: string | null;
  dates: string[];
  excludedDates: string[];
  /** ISO timestamp; used as the default anchor for interval/weekly math. */
  createdAt: string;
}

/** The subset needed to decide whether a day's goal is met. */
export interface HabitGoal {
  goalType: HabitGoalType;
  /** DAY = per-day quota; WEEK/MONTH = cumulative total for the period. */
  goalPeriod: HabitGoalPeriod;
  targetCount: number;
  targetSeconds: number;
}

// --- date-key helpers -------------------------------------------------------

export function parseDateKey(key: string): Date {
  const [y, m, d] = key.split("-").map(Number);
  return new Date(y, (m ?? 1) - 1, d ?? 1);
}

export function addDays(key: string, n: number): string {
  const d = parseDateKey(key);
  d.setDate(d.getDate() + n);
  return isoDateKey(d);
}

/** Whole days from `aKey` to `bKey` (positive if b is later). DST-safe. */
export function daysBetween(aKey: string, bKey: string): number {
  const a = parseDateKey(aKey);
  const b = parseDateKey(bKey);
  const ua = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate());
  const ub = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate());
  return Math.round((ub - ua) / 86_400_000);
}

function startOfWeek(d: Date, weekStartsOn: number): Date {
  const c = new Date(d.getFullYear(), d.getMonth(), d.getDate());
  const diff = (c.getDay() - weekStartsOn + 7) % 7;
  c.setDate(c.getDate() - diff);
  return c;
}

// --- scheduling -------------------------------------------------------------

/** Is the habit active (shown) on `dateKey`? */
export function isScheduledOn(
  h: HabitSchedule,
  dateKey: string,
  weekStartsOn = 1,
): boolean {
  if (h.excludedDates.includes(dateKey)) return false;
  const d = parseDateKey(dateKey);

  switch (h.scheduleType) {
    case "DAILY":
      return true;

    case "WEEKDAYS": {
      if (!h.weekdays.includes(d.getDay())) return false;
      const interval = Math.max(1, h.weekInterval);
      if (interval === 1) return true;
      const anchorKey = h.anchorDate ?? isoDateKey(new Date(h.createdAt));
      const anchorWeek = startOfWeek(parseDateKey(anchorKey), weekStartsOn);
      const thisWeek = startOfWeek(d, weekStartsOn);
      const weeks = Math.round(
        daysBetween(isoDateKey(anchorWeek), isoDateKey(thisWeek)) / 7,
      );
      return ((weeks % interval) + interval) % interval === 0;
    }

    case "INTERVAL": {
      const anchorKey = h.anchorDate ?? isoDateKey(new Date(h.createdAt));
      const diff = daysBetween(anchorKey, dateKey);
      if (diff < 0) return false;
      return diff % Math.max(1, h.intervalDays) === 0;
    }

    case "TIMES_PER_WEEK":
    case "TIMES_PER_MONTH":
    case "TIMES_PER_YEAR":
      // Active every day; the quota is tracked across the period.
      return true;

    case "DATES":
      return h.dates.includes(dateKey);
  }
}

export function isPeriodSchedule(t: HabitScheduleType): boolean {
  return PERIOD_SCHEDULES.includes(t);
}

/** Inclusive [from, to] date-key range of the period containing `dateKey`. */
export function periodRange(
  scheduleType: HabitScheduleType,
  dateKey: string,
  weekStartsOn = 1,
): { from: string; to: string } {
  const d = parseDateKey(dateKey);
  switch (scheduleType) {
    case "TIMES_PER_MONTH": {
      const from = new Date(d.getFullYear(), d.getMonth(), 1);
      const to = new Date(d.getFullYear(), d.getMonth() + 1, 0);
      return { from: isoDateKey(from), to: isoDateKey(to) };
    }
    case "TIMES_PER_YEAR": {
      const from = new Date(d.getFullYear(), 0, 1);
      const to = new Date(d.getFullYear(), 11, 31);
      return { from: isoDateKey(from), to: isoDateKey(to) };
    }
    default: {
      // weekly (and any non-period type falls back to its week)
      const from = startOfWeek(d, weekStartsOn);
      const to = new Date(from);
      to.setDate(to.getDate() + 6);
      return { from: isoDateKey(from), to: isoDateKey(to) };
    }
  }
}

// --- goal completion --------------------------------------------------------

export interface DayProgress {
  count: number;
  seconds: number;
}

export function isGoalMet(g: HabitGoal, p: DayProgress): boolean {
  switch (g.goalType) {
    case "TASK":
      return p.count >= 1;
    case "COUNT":
      return p.count >= Math.max(1, g.targetCount);
    case "TIME":
      return p.seconds >= Math.max(1, g.targetSeconds);
  }
}

/** 0..1 fraction of the day's goal reached. */
export function goalFraction(g: HabitGoal, p: DayProgress): number {
  switch (g.goalType) {
    case "TASK":
      return p.count >= 1 ? 1 : 0;
    case "COUNT":
      return Math.min(1, p.count / Math.max(1, g.targetCount));
    case "TIME":
      return Math.min(1, p.seconds / Math.max(1, g.targetSeconds));
  }
}

// --- display ----------------------------------------------------------------

const WEEKDAY_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

/** Human summary of a schedule, e.g. "Mon, Wed, Fri" or "3× per week". */
export function scheduleSummary(h: HabitSchedule): string {
  switch (h.scheduleType) {
    case "DAILY":
      return "Every day";
    case "WEEKDAYS": {
      const days = [...h.weekdays].sort((a, b) => a - b);
      if (days.length === 7) return "Every day";
      if (days.length === 0) return "No days";
      const label =
        days.length === 5 && days.every((d) => d >= 1 && d <= 5)
          ? "Weekdays"
          : days.length === 2 && days.includes(0) && days.includes(6)
            ? "Weekends"
            : days.map((d) => WEEKDAY_SHORT[d]).join(", ");
      return h.weekInterval > 1 ? `${label} · every ${h.weekInterval}w` : label;
    }
    case "INTERVAL":
      return h.intervalDays === 1 ? "Every day" : `Every ${h.intervalDays} days`;
    case "TIMES_PER_WEEK":
      return `${h.timesPerPeriod}× per week`;
    case "TIMES_PER_MONTH":
      return `${h.timesPerPeriod}× per month`;
    case "TIMES_PER_YEAR":
      return `${h.timesPerPeriod}× per year`;
    case "DATES":
      return h.dates.length === 1
        ? "On 1 date"
        : `On ${h.dates.length} dates`;
  }
}

/** "this week" / "this month" label for period TIME goals. */
export function goalPeriodLabel(period: HabitGoalPeriod): string {
  if (period === "WEEK") return "this week";
  if (period === "MONTH") return "this month";
  return "";
}
