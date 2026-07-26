// Gym log helpers.
//
// The whole feature rests on one idea: the user keeps writing sets the way they
// already do in their notes file — "40-10 57-10 77-8 77-8 77-6" — and the app
// reads as much structure out of that as it can. Parsing never fails: whatever
// can't be read stays in the line as free text, so a set line is always
// saveable and nothing is ever lost.
//
// Notations seen in three years of real notes, all supported:
//   40-10 57-10 77-8      weight-reps pairs
//   32,5-11               decimal comma
//   40 - 8/10/9/8         one weight, several rep counts
//   - 8/5/7               bodyweight reps
//   10lf/10rf             per-set markers (left foot / right foot)
//   130 - 17 -> 145 - 15/9   a jump to a new weight mid-exercise
//   32                    a lone rep count (push-ups)
//   Nicht machen, Knie kaputt   no sets at all — kept verbatim as a note

/** One set read out of a line. Either field may be missing in real entries. */
export interface ParsedSet {
  /** As typed. The unit is whatever that gym's stack says — never converted. */
  weight: number | null;
  reps: number | null;
  /** Per-set marker, e.g. "lf" / "rf". */
  note: string | null;
}

export interface ParsedLine {
  sets: ParsedSet[];
  /** The part of the line that wasn't sets — a comment, a reason, a unit. */
  leftover: string;
  /** True when the whole line turned into sets and nothing was left over. */
  clean: boolean;
}

// "->", "=>": the user moved to a different weight. Anything carried over
// (a pending weight) stops applying at that point.
const GROUP_BREAK = /^(->|=>|→|⇒|➔)$/;
// A lone dash separates weight from reps: "40 - 8/10/9/8".
const DASH = /^[-–—]$/;
// "77,5-7", "24,5-15lf", "60kg×8"
const PAIR = /^(\d+(?:[.,]\d+)?)(?:kg|lbs?)?[-–—x×@](\d+)([A-Za-z]{0,4})$/i;
// A bare number, which is a weight or a rep count depending on context.
const NUMBER = /^(\d+(?:[.,]\d+)?)(?:kg|lbs?)?$/i;
// One rep count with an optional marker: "10", "10lf", "10h".
const REP = /^(\d+)([A-Za-z]{0,4})$/;

/** "32,5" / "77" — the German decimal comma the user's notes are written in. */
export function formatWeight(value: number): string {
  return (Math.round(value * 100) / 100).toString().replace(".", ",");
}

function toNumber(text: string): number {
  return Number.parseFloat(text.replace(",", "."));
}

/** Reads "10lf/10rf" into rep counts. Null when the token isn't rep-shaped. */
function readReps(token: string): { reps: number; note: string | null }[] | null {
  // A dangling slash is just a line that trailed off — "20 - 14/11/".
  const parts = token.split("/").filter((p) => p !== "");
  if (parts.length === 0) return null;

  const out: { reps: number; note: string | null }[] = [];
  for (const part of parts) {
    const m = REP.exec(part);
    if (!m) return null;
    out.push({ reps: Number.parseInt(m[1], 10), note: m[2] || null });
  }
  return out;
}

/**
 * Reads a set line. Never throws and never rejects: anything unreadable comes
 * back in `leftover` so the caller can keep it as written.
 */
export function parseSetLine(raw: string): ParsedLine {
  const text = raw.trim();
  if (!text) return { sets: [], leftover: "", clean: false };

  const sets: ParsedSet[] = [];
  const leftover: string[] = [];

  // The weight in force. "40 - 8/10/9/8" applies 40 to every rep count that
  // follows, until a pair or a group break replaces it.
  let weight: number | null = null;
  // A number we've read but can't place yet: it's a weight if reps follow, and
  // a rep count if the line ends there ("Liegestütze 32").
  let pending: { value: number; text: string } | null = null;

  function dropPending() {
    if (pending) leftover.push(pending.text);
    pending = null;
  }

  for (const token of text.split(/\s+/)) {
    if (GROUP_BREAK.test(token)) {
      dropPending();
      weight = null;
      continue;
    }

    if (DASH.test(token)) {
      // The dash is what turns the held number into a weight.
      if (pending) {
        weight = pending.value;
        pending = null;
      }
      continue;
    }

    const pair = PAIR.exec(token);
    if (pair) {
      dropPending();
      weight = toNumber(pair[1]);
      sets.push({
        weight,
        reps: Number.parseInt(pair[2], 10),
        note: pair[3] || null,
      });
      continue;
    }

    const number = NUMBER.exec(token);
    if (number) {
      const value = toNumber(number[1]);
      const isCount = Number.isInteger(value);

      if (weight !== null && isCount) {
        // Reps at the weight already in force.
        sets.push({ weight, reps: value, note: null });
      } else if (pending && isCount) {
        // Two numbers in a row read as weight then reps: "40 10".
        weight = pending.value;
        pending = null;
        sets.push({ weight, reps: value, note: null });
      } else {
        dropPending();
        pending = { value, text: token };
      }
      continue;
    }

    const reps = readReps(token);
    if (reps) {
      // A slashed or marked rep list. A number still held in front of it is
      // its weight: "60 20/20/15".
      if (pending) {
        weight = pending.value;
        pending = null;
      }
      for (const r of reps) sets.push({ weight, reps: r.reps, note: r.note });
      continue;
    }

    dropPending();
    leftover.push(token);
  }

  if (pending) {
    // A number on its own, with nothing else on the line, is a rep count:
    // "Liegestütze 32", "Klimmzüge (L Sit) 10".
    if (sets.length === 0 && leftover.length === 0 && Number.isInteger(pending.value)) {
      sets.push({ weight: null, reps: pending.value, note: null });
    } else {
      leftover.push(pending.text);
    }
    pending = null;
  }

  // A line with no sets at all is a plain remark — keep it exactly as written
  // rather than as a bag of tokens.
  const rest = sets.length === 0 ? text : leftover.join(" ");

  return { sets, leftover: rest, clean: sets.length > 0 && leftover.length === 0 };
}

/** Renders sets back into the user's own notation. */
export function formatSetLine(sets: ParsedSet[]): string {
  return sets
    .map((s) => {
      const reps = s.reps === null ? "" : `${s.reps}${s.note ?? ""}`;
      if (s.weight === null) return reps || "—";
      return reps ? `${formatWeight(s.weight)}-${reps}` : formatWeight(s.weight);
    })
    .join(" ");
}

// --- what a set is worth -----------------------------------------------------

/**
 * Epley one-rep-max estimate. It's the fairest way to compare a heavy triple
 * against a lighter set of twelve, which is what the progress graph needs.
 */
export function estimate1RM(weight: number | null, reps: number | null): number | null {
  if (weight === null || reps === null || reps <= 0) return null;
  return weight * (1 + reps / 30);
}

/** The set that best represents the session — the heaviest thing done, by e1RM. */
export function bestSet(sets: ParsedSet[]): ParsedSet | null {
  let best: ParsedSet | null = null;
  let bestScore = -1;

  for (const set of sets) {
    // Bodyweight sets have no weight to compare, so reps alone rank them.
    const score = estimate1RM(set.weight, set.reps) ?? (set.weight === null ? (set.reps ?? 0) / 1000 : 0);
    if (score > bestScore) {
      bestScore = score;
      best = set;
    }
  }

  return best;
}

export function topWeight(sets: ParsedSet[]): number | null {
  const weights = sets.map((s) => s.weight).filter((w): w is number => w !== null);
  return weights.length > 0 ? Math.max(...weights) : null;
}

export function best1RM(sets: ParsedSet[]): number | null {
  const values = sets
    .map((s) => estimate1RM(s.weight, s.reps))
    .filter((v): v is number => v !== null);
  return values.length > 0 ? Math.max(...values) : null;
}

export function totalReps(sets: ParsedSet[]): number {
  return sets.reduce((sum, s) => sum + (s.reps ?? 0), 0);
}

/** Weight moved across the exercise. Bodyweight sets contribute nothing. */
export function totalVolume(sets: ParsedSet[]): number {
  return sets.reduce(
    (sum, s) => sum + (s.weight !== null && s.reps !== null ? s.weight * s.reps : 0),
    0,
  );
}

/** "5 sets · top 77 · 41 reps" — the one-line read-out under a set field. */
export function summarizeSets(sets: ParsedSet[]): string {
  if (sets.length === 0) return "";

  const parts = [`${sets.length} ${sets.length === 1 ? "set" : "sets"}`];
  const top = topWeight(sets);
  if (top !== null) parts.push(`top ${formatWeight(top)}`);
  const reps = totalReps(sets);
  if (reps > 0) parts.push(`${reps} ${reps === 1 ? "rep" : "reps"}`);

  return parts.join(" · ");
}

// --- importing the old notes file -------------------------------------------

export interface ImportedExercise {
  name: string;
  raw: string;
}

export interface ImportedSession {
  /** "YYYY-MM-DD". */
  date: string;
  /** The short code written after the date, e.g. "STR". Empty when absent. */
  locationCode: string;
  notes: string;
  exercises: ImportedExercise[];
}

const HEADING = /^#{1,6}\s*(\d{4}-\d{2}-\d{2})\s*(.*)$/;
const EXERCISE = /^\s*\*\*(.+?)\*\*\s*(.*)$/;
const RULE = /^\s*-{3,}\s*$/;

/**
 * Reads the markdown the user has been keeping by hand. Headings are dated
 * sessions, bold lines are exercises, and anything else under a heading is a
 * note about the session as a whole.
 */
export function parseGymMarkdown(text: string): ImportedSession[] {
  const sessions: ImportedSession[] = [];
  let current: ImportedSession | null = null;

  for (const line of text.split(/\r?\n/)) {
    const heading = HEADING.exec(line);
    if (heading) {
      current = {
        date: heading[1],
        locationCode: heading[2].trim(),
        notes: "",
        exercises: [],
      };
      sessions.push(current);
      continue;
    }

    if (!current) continue; // anything before the first date has no home
    if (!line.trim() || RULE.test(line)) continue;

    const exercise = EXERCISE.exec(line);
    if (exercise) {
      const name = exercise[1].trim();
      if (name) current.exercises.push({ name, raw: exercise[2].trim() });
      continue;
    }

    current.notes = current.notes ? `${current.notes}\n${line.trim()}` : line.trim();
  }

  // Headings with nothing under them are usually a half-written entry, not a
  // session that happened.
  return sessions.filter((s) => s.exercises.length > 0 || s.notes);
}

/** Case/space-insensitive key used to match exercise names against each other. */
export function exerciseKey(name: string): string {
  return name.trim().toLowerCase().replace(/\s+/g, " ");
}
