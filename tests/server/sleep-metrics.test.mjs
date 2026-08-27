import assert from "node:assert/strict";
import test from "node:test";

import {
  deriveSleepMetrics,
  efficiencyPercent,
  inferSleepMinutes,
  stageMinutes,
  AWAKE_STAGES,
  AWAKE_IN_BED_STAGES,
  DEEP_STAGES,
  OUT_OF_BED_STAGES,
} from "../../src/lib/health/sleep-metrics.ts";

const NIGHT = "2026-08-26T22:00:00.000Z";

/** Stage helper: hours offset from the start of the night. */
function stage(name, fromHour, toHour) {
  const base = Date.parse(NIGHT);
  return {
    stage: name,
    startTime: new Date(base + fromHour * 3600_000).toISOString(),
    endTime: new Date(base + toHour * 3600_000).toISOString(),
  };
}

test("counts awake-in-bed and out-of-bed apart from awake", () => {
  const stages = [
    stage("AWAKE", 0, 0.5),
    stage("AWAKE_IN_BED", 0.5, 1),
    stage("OUT_OF_BED", 1, 1.25),
  ];

  assert.equal(stageMinutes(stages, AWAKE_STAGES), 30);
  assert.equal(stageMinutes(stages, AWAKE_IN_BED_STAGES), 30);
  assert.equal(stageMinutes(stages, OUT_OF_BED_STAGES), 15);
});

test("normalizes stage names before matching", () => {
  assert.equal(stageMinutes([stage("out of bed", 0, 1)], OUT_OF_BED_STAGES), 60);
  assert.equal(stageMinutes([stage(" deep ", 0, 1)], DEEP_STAGES), 60);
});

test("derives latency from the session start to the first asleep stage", () => {
  const metrics = deriveSleepMetrics(new Date(NIGHT), [
    stage("AWAKE", 0, 0.5),
    stage("LIGHT", 0.5, 3),
    stage("DEEP", 3, 5),
  ]);

  assert.equal(metrics.latencyMinutes, 30);
});

test("counts wake after sleep onset but not before or after it", () => {
  const metrics = deriveSleepMetrics(new Date(NIGHT), [
    // Before onset: latency, not WASO.
    stage("AWAKE", 0, 0.5),
    stage("LIGHT", 0.5, 2),
    // Bracketed by sleep: WASO.
    stage("AWAKE", 2, 2.25),
    stage("DEEP", 2.25, 5),
    // After the final sleep: up for the day, not WASO.
    stage("AWAKE", 5, 6),
  ]);

  assert.equal(metrics.wasoMinutes, 15);
  assert.equal(metrics.awakeningCount, 1);
});

test("treats adjacent awake stages as a single waking", () => {
  const metrics = deriveSleepMetrics(new Date(NIGHT), [
    stage("LIGHT", 0, 2),
    // One trip out of bed, recorded as two touching stages.
    stage("AWAKE", 2, 2.25),
    stage("OUT_OF_BED", 2.25, 2.5),
    stage("LIGHT", 2.5, 5),
    // A separate waking later.
    stage("AWAKE", 5, 5.25),
    stage("REM", 5.25, 7),
  ]);

  assert.equal(metrics.awakeningCount, 2);
  assert.equal(metrics.wasoMinutes, 45);
});

test("puts the midpoint between sleep onset and the final wake", () => {
  const metrics = deriveSleepMetrics(new Date(NIGHT), [
    stage("AWAKE", 0, 1),
    stage("LIGHT", 1, 4),
    stage("DEEP", 4, 7),
  ]);

  // Onset at +1h, final wake at +7h, so the midpoint sits at +4h.
  assert.equal(metrics.midpoint.toISOString(), "2026-08-27T02:00:00.000Z");
});

test("returns nulls when no stage timeline was reported", () => {
  const metrics = deriveSleepMetrics(new Date(NIGHT), []);

  assert.deepEqual(metrics, {
    latencyMinutes: null,
    wasoMinutes: null,
    awakeningCount: null,
    midpoint: null,
  });
});

test("returns nulls when the timeline contains no sleep at all", () => {
  const metrics = deriveSleepMetrics(new Date(NIGHT), [stage("AWAKE", 0, 2)]);

  assert.equal(metrics.latencyMinutes, null);
  assert.equal(metrics.midpoint, null);
});

test("orders an unsorted timeline before reading it", () => {
  const shuffled = [stage("DEEP", 4, 7), stage("AWAKE", 0, 1), stage("LIGHT", 1, 4)];
  const ordered = [stage("AWAKE", 0, 1), stage("LIGHT", 1, 4), stage("DEEP", 4, 7)];

  assert.deepEqual(
    deriveSleepMetrics(new Date(NIGHT), shuffled),
    deriveSleepMetrics(new Date(NIGHT), ordered),
  );
});

test("infers asleep minutes from stages, preferring them over a duration", () => {
  const stages = [stage("LIGHT", 0, 3), stage("DEEP", 3, 5), stage("AWAKE", 5, 6)];

  assert.equal(inferSleepMinutes(360, 60, stages), 300);
});

test("falls back to duration minus awake when no stages are present", () => {
  assert.equal(inferSleepMinutes(480, 45, []), 435);
  assert.equal(inferSleepMinutes(480, null, []), null);
});

test("reports efficiency to one decimal, and null without a sleep total", () => {
  assert.equal(efficiencyPercent(420, 480), 87.5);
  assert.equal(efficiencyPercent(null, 480), null);
  assert.equal(efficiencyPercent(420, 0), null);
});
