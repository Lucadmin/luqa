import assert from "node:assert/strict";
import test from "node:test";

import {
  isScheduledOn,
  rollingLookbackDays,
  scheduleSummary,
} from "../../src/lib/habits.ts";

/**
 * The browser and the phone both decide, on their own, whether a habit is due.
 * These are the cases the Dart port is held to as well
 * (`mobile/test/features/habits/habit_schedule_test.dart`), because a rule the
 * two clients disagree about is a habit that is due on one device and not the
 * other.
 */
function habit(overrides = {}) {
  return {
    scheduleType: "INTERVAL",
    weekdays: [],
    weekInterval: 1,
    intervalDays: 2,
    intervalFromLastDone: false,
    timesPerPeriod: 3,
    anchorDate: "2026-03-09",
    dates: [],
    excludedDates: [],
    createdAt: "2026-03-09T08:00:00.000Z",
    ...overrides,
  };
}

/** "Was it done that day", from a list of the days it was. */
const doneOnAny =
  (...days) =>
  (day) =>
    days.includes(day);

test("a fixed interval keeps its grid however it actually went", () => {
  const shave = habit();
  const done = doneOnAny("2026-03-09", "2026-03-12");
  assert.equal(isScheduledOn(shave, "2026-03-11", 1, done), true);
  // The day after doing it, the fixed grid still says yes — which is the
  // behaviour a rolling interval exists to replace.
  assert.equal(isScheduledOn(shave, "2026-03-13", 1, done), true);
});

test("a rolling interval is due from the anchor when never done", () => {
  const shave = habit({ intervalFromLastDone: true });
  const never = doneOnAny();
  assert.equal(isScheduledOn(shave, "2026-03-08", 1, never), false);
  assert.equal(isScheduledOn(shave, "2026-03-09", 1, never), true);
  // Overdue means due again tomorrow, not due again in two days.
  assert.equal(isScheduledOn(shave, "2026-03-10", 1, never), true);
});

test("a rolling interval rests the day after, and comes back the next", () => {
  const shave = habit({ intervalFromLastDone: true });
  const done = doneOnAny("2026-03-09");
  assert.equal(isScheduledOn(shave, "2026-03-09", 1, done), true);
  assert.equal(isScheduledOn(shave, "2026-03-10", 1, done), false);
  assert.equal(isScheduledOn(shave, "2026-03-11", 1, done), true);
});

test("a missed turn shifts every turn after it", () => {
  // Shaved Monday the 9th, missed Wednesday, shaved Thursday the 12th.
  const shave = habit({ intervalFromLastDone: true });
  const done = doneOnAny("2026-03-09", "2026-03-12");

  assert.equal(isScheduledOn(shave, "2026-03-11", 1, done), true);
  // Thursday was still due — an overdue habit keeps asking.
  assert.equal(isScheduledOn(shave, "2026-03-12", 1, done), true);
  // And from there the cycle counts from Thursday, not from Monday.
  assert.equal(isScheduledOn(shave, "2026-03-13", 1, done), false);
  assert.equal(isScheduledOn(shave, "2026-03-14", 1, done), true);
});

test("a rolling habit still shows on the day it was done", () => {
  // Otherwise ticking one would make it vanish out of the list it was ticked in.
  const shave = habit({ intervalFromLastDone: true });
  assert.equal(
    isScheduledOn(shave, "2026-03-10", 1, doneOnAny("2026-03-10")),
    true,
  );
});

test("a rolling interval looks back the whole interval", () => {
  const weekly = habit({ intervalDays: 4, intervalFromLastDone: true });
  const done = doneOnAny("2026-03-10");
  assert.equal(isScheduledOn(weekly, "2026-03-11", 1, done), false);
  assert.equal(isScheduledOn(weekly, "2026-03-13", 1, done), false);
  assert.equal(isScheduledOn(weekly, "2026-03-14", 1, done), true);
});

test("a rolling interval never looks behind its anchor", () => {
  const monthly = habit({ intervalDays: 30, intervalFromLastDone: true });
  const asked = [];
  const record = (day) => {
    asked.push(day);
    return false;
  };
  assert.equal(isScheduledOn(monthly, "2026-03-11", 1, record), true);
  assert.deepEqual(asked, ["2026-03-11", "2026-03-10", "2026-03-09"]);
});

test("an excluded date still wins over a rolling interval", () => {
  const skipped = habit({
    intervalFromLastDone: true,
    excludedDates: ["2026-03-11"],
  });
  assert.equal(isScheduledOn(skipped, "2026-03-11", 1, doneOnAny()), false);
});

test("without history a rolling habit nags rather than hiding", () => {
  // A caller that cannot answer "was it done" gets the habit shown, not
  // silently dropped from a day it may well be due on.
  assert.equal(isScheduledOn(habit({ intervalFromLastDone: true }), "2026-03-13"), true);
});

test("the lookback is the interval, and only for rolling habits", () => {
  assert.equal(rollingLookbackDays(habit({ intervalFromLastDone: true })), 2);
  assert.equal(rollingLookbackDays(habit()), 0);
  assert.equal(rollingLookbackDays(habit({ scheduleType: "DAILY" })), 0);
});

test("the summary says which end an interval is counted from", () => {
  assert.equal(scheduleSummary(habit()), "Every 2 days");
  assert.equal(
    scheduleSummary(habit({ intervalFromLastDone: true })),
    "Every 2 days · from the last",
  );
  // Counted from either end, every day is every day.
  assert.equal(
    scheduleSummary(habit({ intervalDays: 1, intervalFromLastDone: true })),
    "Every day",
  );
});
