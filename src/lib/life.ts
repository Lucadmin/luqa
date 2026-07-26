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
  id: string;
  name: string;
  color: string;
  startWeek: number;
  endWeek: number; // inclusive; clamped to the grid
}

/**
 * Every period covering each week in [0, total), oldest-start first. Most
 * weeks have zero or one entry; more than one means overlapping periods,
 * which the caller renders as a blended tint (whole-life wall) or as
 * hard-edged colour bands (cells roomy enough to read one).
 */
export function buildCellPeriods(
  ranges: PeriodRange[],
  total: number,
): PeriodRange[][] {
  const cells: PeriodRange[][] = Array.from({ length: total }, () => []);
  const ordered = [...ranges].sort((a, b) => a.startWeek - b.startWeek);
  for (const r of ordered) {
    const from = Math.max(0, r.startWeek);
    const to = Math.min(total - 1, r.endWeek);
    for (let i = from; i <= to; i++) cells[i].push(r);
  }
  return cells;
}

function hexToRgb(hex: string): [number, number, number] {
  return [
    parseInt(hex.slice(1, 3), 16),
    parseInt(hex.slice(3, 5), 16),
    parseInt(hex.slice(5, 7), 16),
  ];
}

function rgbToHsl(r: number, g: number, b: number): [number, number, number] {
  r /= 255;
  g /= 255;
  b /= 255;
  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const l = (max + min) / 2;
  let h = 0;
  let s = 0;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
    else if (max === g) h = (b - r) / d + 2;
    else h = (r - g) / d + 4;
    h /= 6;
  }
  return [h * 360, s, l];
}

function hslToHex(h: number, s: number, l: number): string {
  const hue = (((h % 360) + 360) % 360) / 360;
  const hue2rgb = (p: number, q: number, t: number) => {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  let r: number;
  let g: number;
  let b: number;
  if (s === 0) {
    r = g = b = l;
  } else {
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, hue + 1 / 3);
    g = hue2rgb(p, q, hue);
    b = hue2rgb(p, q, hue - 1 / 3);
  }
  const toHex = (x: number) => Math.round(x * 255).toString(16).padStart(2, "0");
  return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

/**
 * Merge several period colours into one tint, for cells too small to render
 * as distinct bands. Hue is averaged circularly (as points on the colour
 * wheel) rather than as raw RGB, so e.g. pink + sky lands on a real
 * violet-blue instead of a muddy grey-brown.
 */
export function blendPeriodColor(colors: string[]): string | null {
  if (colors.length === 0) return null;
  if (colors.length === 1) return colors[0];
  let sx = 0;
  let sy = 0;
  let sSat = 0;
  let sLig = 0;
  for (const hex of colors) {
    const [r, g, b] = hexToRgb(hex);
    const [h, s, l] = rgbToHsl(r, g, b);
    const rad = (h * Math.PI) / 180;
    sx += Math.cos(rad);
    sy += Math.sin(rad);
    sSat += s;
    sLig += l;
  }
  const avgHue = (Math.atan2(sy / colors.length, sx / colors.length) * 180) / Math.PI;
  const avgSat = Math.min(1, (sSat / colors.length) * 1.08);
  const avgLig = sLig / colors.length;
  return hslToHex(avgHue, avgSat, avgLig);
}

/**
 * Hard-edged colour bands for cells roomy enough to read as "more than one
 * colour" — oldest period on the left, like a timeline. A single period (the
 * common case) renders as a flat colour, unchanged from before.
 */
export function periodStripeBackground(colors: string[]): string | null {
  if (colors.length === 0) return null;
  if (colors.length === 1) return colors[0];
  const n = colors.length;
  const stops = colors.flatMap((hex, idx) => [
    `${hex} ${((idx / n) * 100).toFixed(2)}%`,
    `${hex} ${(((idx + 1) / n) * 100).toFixed(2)}%`,
  ]);
  return `linear-gradient(90deg, ${stops.join(", ")})`;
}
