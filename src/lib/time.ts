// Time + geometry helpers for the day timeline.
// The timeline works in "minutes since local midnight" for layout, and ISO
// UTC strings for storage/transport.

export const SNAP_MINUTES = 5;
export const MINUTES_PER_DAY = 24 * 60;

/**
 * Hour at which the logical day flips. Entries that start between 00:00 and
 * DAY_START_HOUR (exclusive) are attributed to the *previous* calendar day for
 * stats purposes. The visual timeline still runs midnight-to-midnight.
 */
export const DAY_START_HOUR = 3;

/** Pixels per hour on the timeline. 5 min => HOUR_HEIGHT/12 px. */
export const HOUR_HEIGHT = 64;
export const PX_PER_MINUTE = HOUR_HEIGHT / 60;

/** Height of one day on the continuous timeline. */
export const DAY_HEIGHT = MINUTES_PER_DAY * PX_PER_MINUTE;

/** Round a minute value to the nearest 5-minute block. */
export function snapMinutes(minutes: number, snap = SNAP_MINUTES): number {
  return Math.round(minutes / snap) * snap;
}

/** Clamp a minute value into [0, MINUTES_PER_DAY]. */
export function clampToDay(minutes: number): number {
  return Math.max(0, Math.min(MINUTES_PER_DAY, minutes));
}

/** Local midnight for the date that `d` falls on. */
export function startOfLocalDay(d: Date): Date {
  const c = new Date(d);
  c.setHours(0, 0, 0, 0);
  return c;
}

export function endOfLocalDay(d: Date): Date {
  const c = startOfLocalDay(d);
  c.setDate(c.getDate() + 1);
  return c;
}

/** Calendar-safe day arithmetic — survives DST shifts and month ends. */
export function addDays(d: Date, n: number): Date {
  const c = new Date(d);
  c.setDate(c.getDate() + n);
  return c;
}

/**
 * Stable integer index for a calendar date, independent of timezone and DST.
 * Differences between two `dayNumber`s are exact day counts, which is what the
 * infinite timeline uses to map dates onto scroll offsets.
 */
export function dayNumber(d: Date): number {
  return Math.floor(
    Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()) / 86_400_000,
  );
}

/** Minutes since local midnight for an instant. */
export function minutesSinceMidnight(d: Date): number {
  return d.getHours() * 60 + d.getMinutes() + d.getSeconds() / 60;
}

/** Convert minutes-since-midnight (on `day`) to an absolute Date. */
export function minutesToDate(day: Date, minutes: number): Date {
  const base = startOfLocalDay(day);
  base.setMinutes(base.getMinutes() + minutes);
  return base;
}

export function minutesToY(minutes: number): number {
  return minutes * PX_PER_MINUTE;
}

export function yToMinutes(y: number): number {
  return y / PX_PER_MINUTE;
}

/** "9:05", "14:30" — 24h clock, used on the dial and entry rows. */
export function formatClock(minutes: number): string {
  const m = ((Math.round(minutes) % MINUTES_PER_DAY) + MINUTES_PER_DAY) %
    MINUTES_PER_DAY;
  const h = Math.floor(m / 60);
  const mm = Math.floor(m % 60);
  return `${h}:${String(mm).padStart(2, "0")}`;
}

/** "1h 25m", "45m", "2h" — durations for entry rows and totals. */
export function formatDuration(minutes: number): string {
  const total = Math.max(0, Math.round(minutes));
  const h = Math.floor(total / 60);
  const m = total % 60;
  if (h === 0) return `${m}m`;
  if (m === 0) return `${h}h`;
  return `${h}h ${m}m`;
}

/** "2:00:00", "0:45:30" — H:MM:SS for habit timers. */
export function formatHMS(seconds: number): string {
  const total = Math.max(0, Math.round(seconds));
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

/** Compact goal label for a duration in seconds: "2h", "1h 30m", "20m". */
export function formatSecondsShort(seconds: number): string {
  return formatDuration(Math.round(seconds / 60));
}

export function isoDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

const MONTH_LABELS = [
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
];

/**
 * "2026-07-12" → "12 Jul", or "12 Jul 2025" once it is not this year. Parsed by
 * hand rather than through Date so the label never shifts a timezone.
 */
export function formatDayLabel(key: string, today = new Date()): string {
  const [year, month, day] = key.split("-").map(Number);
  if (!year || !month || !day) return key;
  const label = `${day} ${MONTH_LABELS[month - 1] ?? ""}`.trim();
  return year === today.getFullYear() ? label : `${label} ${year}`;
}

/**
 * Logical day key for stats: shifts the time back by `startHour` so that
 * entries starting before that hour are attributed to the previous calendar
 * day. Client-side only (uses local timezone).
 */
export function logicalDayKey(d: Date, startHour = DAY_START_HOUR): string {
  return isoDateKey(new Date(d.getTime() - startHour * 3_600_000));
}

/** Midnight of the logical day that the instant `d` belongs to. */
export function startOfViewDay(d: Date, startHour = DAY_START_HOUR): Date {
  return startOfLocalDay(new Date(d.getTime() - startHour * 3_600_000));
}
