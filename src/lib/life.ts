// Pure helpers for the "life in weeks" overview. No server- or client-only
// imports so this can be used from API routes and React components alike.
//
// The grid models age-weeks: week 0 is the week the user was born, and every
// row is one year of 52 weeks. 52×7 = 364 days, so the grid drifts ~1.25 days
// per year against the calendar — this is the same simplification the classic
// "Your Life in Weeks" posters make, and it keeps rows aligned to birthdays.

export const WEEKS_PER_YEAR = 52;
const MS_PER_DAY = 86_400_000;
const MS_PER_WEEK = 7 * MS_PER_DAY;

export const MIN_LIFE_YEARS = 40;
export const MAX_LIFE_YEARS = 150;
export const DEFAULT_LIFE_YEARS = 90;

/** A curated palette for life-period bands. */
export const PERIOD_PALETTE = [
  "#6366f1", // indigo
  "#ec4899", // pink
  "#f97316", // orange
  "#10b981", // emerald
  "#0ea5e9", // sky
  "#eab308", // yellow
  "#8b5cf6", // violet
  "#ef4444", // red
  "#14b8a6", // teal
  "#a855f7", // purple
] as const;

/** Parse a "YYYY-MM-DD" date-key into a UTC-midnight timestamp (ms). */
export function dateKeyToUtc(key: string): number {
  const [y, m, d] = key.split("-").map(Number);
  return Date.UTC(y, (m ?? 1) - 1, d ?? 1);
}

/** Format a Date (or ms) as a "YYYY-MM-DD" key using its UTC parts. */
export function toDateKey(value: Date | number): string {
  const d = value instanceof Date ? value : new Date(value);
  return d.toISOString().slice(0, 10);
}

/**
 * 0-based age-week index for `dateKey` relative to `birthKey`. Dates before
 * birth clamp to 0. Both arguments are "YYYY-MM-DD".
 */
export function weekIndexFor(birthKey: string, dateKey: string): number {
  const diff = dateKeyToUtc(dateKey) - dateKeyToUtc(birthKey);
  if (diff <= 0) return 0;
  return Math.floor(diff / MS_PER_WEEK);
}

/** UTC-midnight ms of the first day of a given age-week. */
export function weekStartUtc(birthKey: string, weekIndex: number): number {
  return dateKeyToUtc(birthKey) + weekIndex * MS_PER_WEEK;
}

/** Total number of week-cells rendered for a given life expectancy. */
export function totalWeeks(lifeExpectancyYears: number): number {
  return lifeExpectancyYears * WEEKS_PER_YEAR;
}

/** Row (age in years) and column (week-of-year) for a week index. */
export function gridPosition(weekIndex: number): { row: number; col: number } {
  return {
    row: Math.floor(weekIndex / WEEKS_PER_YEAR),
    col: weekIndex % WEEKS_PER_YEAR,
  };
}

export interface LifeStats {
  /** Age-week index of the current week (clamped to the grid). */
  currentWeek: number;
  /** Whole weeks lived so far. */
  weeksLived: number;
  /** Weeks remaining until the end of the grid (0 if past it). */
  weeksRemaining: number;
  /** Total cells in the grid. */
  totalWeeks: number;
  /** Completed years lived. */
  years: number;
  /** Leftover weeks past the last whole year. */
  weeksIntoYear: number;
  /** Fraction of the grid already lived, 0..1. */
  fractionLived: number;
}

/** Derive the headline life stats for `birthKey` as of `todayKey`. */
export function lifeStats(
  birthKey: string,
  lifeExpectancyYears: number,
  todayKey: string,
): LifeStats {
  const total = totalWeeks(lifeExpectancyYears);
  const raw = weekIndexFor(birthKey, todayKey);
  const currentWeek = Math.min(raw, Math.max(0, total - 1));
  const weeksLived = Math.min(raw, total);
  return {
    currentWeek,
    weeksLived,
    weeksRemaining: Math.max(0, total - weeksLived),
    totalWeeks: total,
    years: Math.floor(raw / WEEKS_PER_YEAR),
    weeksIntoYear: raw % WEEKS_PER_YEAR,
    fractionLived: total > 0 ? Math.min(1, weeksLived / total) : 0,
  };
}

export interface PeriodRange {
  color: string;
  startWeek: number;
  endWeek: number; // inclusive; clamped to the grid
}

/**
 * Build a per-cell colour map. For overlapping periods the one that starts
 * latest wins the cell colour (its band sits "on top"), which reads well while
 * the legend still lists every period.
 */
export function buildCellColors(
  ranges: PeriodRange[],
  total: number,
): (string | null)[] {
  const colors = new Array<string | null>(total).fill(null);
  // Sort so later-starting periods are applied last and therefore win.
  const ordered = [...ranges].sort((a, b) => a.startWeek - b.startWeek);
  for (const r of ordered) {
    const from = Math.max(0, r.startWeek);
    const to = Math.min(total - 1, r.endWeek);
    for (let i = from; i <= to; i++) colors[i] = r.color;
  }
  return colors;
}
