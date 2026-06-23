// Time + geometry helpers for the day timeline.
// The timeline works in "minutes since local midnight" for layout, and ISO
// UTC strings for storage/transport.

export const SNAP_MINUTES = 5;
export const MINUTES_PER_DAY = 24 * 60;

/** Pixels per hour on the timeline. 5 min => HOUR_HEIGHT/12 px. */
export const HOUR_HEIGHT = 64;
export const PX_PER_MINUTE = HOUR_HEIGHT / 60;

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

/**
 * Split the interval [start, end) at every local midnight it crosses, yielding
 * one piece per local day. A same-day interval returns a single piece. Used to
 * keep an entry that runs past 12am from belonging to two days at once — each
 * day gets its own entry instead.
 */
export function splitAtMidnight(
  start: Date,
  end: Date,
): { start: Date; end: Date }[] {
  const pieces: { start: Date; end: Date }[] = [];
  let segStart = new Date(start);
  let nextMidnight = endOfLocalDay(segStart);
  while (nextMidnight < end) {
    pieces.push({ start: segStart, end: nextMidnight });
    segStart = nextMidnight;
    nextMidnight = endOfLocalDay(segStart);
  }
  pieces.push({ start: segStart, end: new Date(end) });
  return pieces;
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

export function isoDateKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}
