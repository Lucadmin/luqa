// Pure helpers for the "life in weeks" overview. No server- or client-only
// imports so this can be used from API routes and React components alike.
//
// The grid models age-weeks: week 0 is the week the user was born, and every
// row is one calendar year of 52 cells. Each row starts on the user's birthday.
// Because calendar years are 365 or 366 days, the final cell in a row can cover
// eight or nine days instead of seven.

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

/** UTC timestamp of the birthday that begins a given age-year. */
function birthdayUtcForAge(birthKey: string, age: number): number {
  const [birthYear, birthMonth, birthDay] = birthKey.split("-").map(Number);
  const year = birthYear + age;
  // Clamp 29 February to 28 February in non-leap years instead of allowing
  // Date.UTC to roll it into March.
  const lastDayOfMonth = new Date(Date.UTC(year, birthMonth, 0)).getUTCDate();
  return Date.UTC(year, birthMonth - 1, Math.min(birthDay, lastDayOfMonth));
}

/**
 * 0-based age-week index for `dateKey` relative to `birthKey`. Dates before
 * birth clamp to 0. Each 52-cell row is anchored to the birthday that starts
 * that age-year; any extra day(s) at the end of the year stay in its last cell.
 * Both arguments are "YYYY-MM-DD".
 */
export function weekIndexFor(birthKey: string, dateKey: string): number {
  const date = dateKeyToUtc(dateKey);
  const birth = dateKeyToUtc(birthKey);
  if (date <= birth) return 0;

  const [birthYear] = birthKey.split("-").map(Number);
  const [year] = dateKey.split("-").map(Number);
  let age = year - birthYear;
  if (date < birthdayUtcForAge(birthKey, age)) age -= 1;
  if (age < 0) return 0;

  const rowStart = birthdayUtcForAge(birthKey, age);
  const weekInYear = Math.min(
    WEEKS_PER_YEAR - 1,
    Math.floor((date - rowStart) / MS_PER_WEEK),
  );
  return age * WEEKS_PER_YEAR + weekInYear;
}

/** UTC-midnight ms of the first day of a given age-week. */
export function weekStartUtc(birthKey: string, weekIndex: number): number {
  const { row, col } = gridPosition(weekIndex);
  return birthdayUtcForAge(birthKey, row) + col * MS_PER_WEEK;
}

/**
 * UTC-midnight ms of the final day represented by an age-week. The last cell
 * in each row ends the day before the next birthday.
 */
export function weekEndUtc(birthKey: string, weekIndex: number): number {
  const { row, col } = gridPosition(weekIndex);
  const nominalEnd = weekStartUtc(birthKey, weekIndex) + 6 * MS_PER_DAY;
  const dayBeforeNextBirthday =
    birthdayUtcForAge(birthKey, row + 1) - MS_PER_DAY;
  if (col === WEEKS_PER_YEAR - 1) return dayBeforeNextBirthday;
  return Math.min(nominalEnd, dayBeforeNextBirthday);
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

/**
 * Real calendar age: whole years elapsed, plus whole weeks since the last
 * birthday. Uses actual dates rather than dividing the age-week count by 52
 * (which drifts, because a year is ~52.18 weeks and would overstate the age).
 */
export function calendarAge(
  birthKey: string,
  todayKey: string,
): { years: number; weeksIntoYear: number } {
  const [birthYear] = birthKey.split("-").map(Number);
  const [todayYear] = todayKey.split("-").map(Number);
  const today = dateKeyToUtc(todayKey);
  let years = todayYear - birthYear;
  if (today < birthdayUtcForAge(birthKey, years)) years -= 1;
  if (years < 0) return { years: 0, weeksIntoYear: 0 };
  const lastBirthday = birthdayUtcForAge(birthKey, years);
  const weeksIntoYear = Math.max(
    0,
    Math.floor((today - lastBirthday) / MS_PER_WEEK),
  );
  return { years, weeksIntoYear };
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
  const { years, weeksIntoYear } = calendarAge(birthKey, todayKey);
  return {
    currentWeek,
    weeksLived,
    weeksRemaining: Math.max(0, total - weeksLived),
    totalWeeks: total,
    years,
    weeksIntoYear,
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
