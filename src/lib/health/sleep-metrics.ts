import type { SleepStageDTO } from "@/lib/types";

// Health Connect's stage vocabulary, normalized. AWAKE_IN_BED and OUT_OF_BED are
// kept apart from AWAKE on purpose: lying awake and getting up say different
// things about a night, and collapsing them loses the distinction for good.
export const AWAKE_STAGES = new Set(["AWAKE", "RESTLESS"]);
export const AWAKE_IN_BED_STAGES = new Set(["AWAKE_IN_BED"]);
export const OUT_OF_BED_STAGES = new Set(["OUT_OF_BED"]);
export const LIGHT_STAGES = new Set(["LIGHT"]);
export const DEEP_STAGES = new Set(["DEEP"]);
export const REM_STAGES = new Set(["REM"]);
export const UNKNOWN_STAGES = new Set(["UNKNOWN"]);
export const ASLEEP_STAGES = new Set([
  "ASLEEP",
  "SLEEPING",
  "LIGHT",
  "DEEP",
  "REM",
]);
// Every stage that means "awake while the session was running".
export const INTERRUPTION_STAGES = new Set([
  ...AWAKE_STAGES,
  ...AWAKE_IN_BED_STAGES,
  ...OUT_OF_BED_STAGES,
]);

export function minutesBetween(start: Date | string, end: Date | string): number {
  const startMs = typeof start === "string" ? Date.parse(start) : start.getTime();
  const endMs = typeof end === "string" ? Date.parse(end) : end.getTime();
  return Math.max(0, Math.round((endMs - startMs) / 60000));
}

export function normalizeStageName(stage: string): string {
  return stage.trim().toUpperCase().replace(/\s+/g, "_");
}

export function stageMinutes(
  stages: SleepStageDTO[],
  names: Set<string>,
): number {
  return stages.reduce((total, stage) => {
    const name = normalizeStageName(stage.stage);
    if (!names.has(name)) return total;
    return total + minutesBetween(stage.startTime, stage.endTime);
  }, 0);
}

export function inferSleepMinutes(
  durationMinutes: number,
  awakeMinutes: number | null,
  stages: SleepStageDTO[],
): number | null {
  const stagedAsleep = stageMinutes(stages, ASLEEP_STAGES);
  if (stagedAsleep > 0) return stagedAsleep;
  if (awakeMinutes !== null) return Math.max(0, durationMinutes - awakeMinutes);
  return null;
}

/** The shape of a night, read off the stage timeline once. */
export interface DerivedSleepMetrics {
  latencyMinutes: number | null;
  wasoMinutes: number | null;
  awakeningCount: number | null;
  midpoint: Date | null;
}

// Everything here needs the ordered stage timeline; a session that arrives with
// only summary totals gets nulls rather than numbers invented from a duration.
export function deriveSleepMetrics(
  startTime: Date,
  stages: SleepStageDTO[],
): DerivedSleepMetrics {
  const empty: DerivedSleepMetrics = {
    latencyMinutes: null,
    wasoMinutes: null,
    awakeningCount: null,
    midpoint: null,
  };
  if (stages.length === 0) return empty;

  const ordered = [...stages].sort(
    (a, b) => Date.parse(a.startTime) - Date.parse(b.startTime),
  );
  const asleep = ordered.filter((stage) =>
    ASLEEP_STAGES.has(normalizeStageName(stage.stage)),
  );
  if (asleep.length === 0) return empty;

  const onset = new Date(asleep[0].startTime);
  const finalWake = asleep.reduce(
    (latest, stage) =>
      Date.parse(stage.endTime) > latest.getTime()
        ? new Date(stage.endTime)
        : latest,
    new Date(asleep[0].endTime),
  );

  // Only interruptions bracketed by sleep count: time before the first sleep is
  // latency, and time after the last is simply being up for the day.
  const interruptions = ordered.filter(
    (stage) =>
      INTERRUPTION_STAGES.has(normalizeStageName(stage.stage)) &&
      Date.parse(stage.startTime) >= onset.getTime() &&
      Date.parse(stage.endTime) <= finalWake.getTime(),
  );

  // Adjacent awake stages (an AWAKE that rolls into OUT_OF_BED) are one waking.
  let awakeningCount = 0;
  let previousEnd = Number.NEGATIVE_INFINITY;
  for (const stage of interruptions) {
    if (Date.parse(stage.startTime) > previousEnd) awakeningCount++;
    previousEnd = Math.max(previousEnd, Date.parse(stage.endTime));
  }

  return {
    latencyMinutes: minutesBetween(startTime, onset),
    wasoMinutes: interruptions.reduce(
      (total, stage) => total + minutesBetween(stage.startTime, stage.endTime),
      0,
    ),
    awakeningCount,
    midpoint: new Date((onset.getTime() + finalWake.getTime()) / 2),
  };
}

export function efficiencyPercent(
  sleepMinutes: number | null,
  inBedMinutes: number,
): number | null {
  if (sleepMinutes === null || inBedMinutes <= 0) return null;
  return Math.round((sleepMinutes / inBedMinutes) * 1000) / 10;
}
