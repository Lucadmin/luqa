import assert from "node:assert/strict";
import test from "node:test";

import { profileUpdateData } from "../../src/lib/person-profile.ts";
import {
  personProfileSchema,
  updatePersonSchema,
} from "../../src/lib/validations.ts";

// The birthday is the part of a person most likely to be written wrong, and
// wrong here means a confidently incorrect age next to somebody's name.

test("a birthday is written as a unit, so a year cannot be left stale", () => {
  // Correcting 14 March 1994 to 3 April: without treating the birthday as one
  // value, the year would survive from a birthday that no longer exists.
  const data = profileUpdateData({ birthdayMonth: 4, birthdayDay: 3 });

  assert.equal(data.birthdayMonth, 4);
  assert.equal(data.birthdayDay, 3);
  assert.equal(data.birthdayYear, null);
});

test("a year given with the day and month is kept", () => {
  const data = profileUpdateData({
    birthdayYear: 1997,
    birthdayMonth: 9,
    birthdayDay: 4,
  });

  assert.equal(data.birthdayYear, 1997);
});

test("a body that mentions no birthday leaves the birthday alone", () => {
  // Renaming somebody must not clear the birthday they already had.
  const data = profileUpdateData({ nickname: "Jo" });

  assert.equal("birthdayMonth" in data, false);
  assert.equal("birthdayDay" in data, false);
  assert.equal("birthdayYear" in data, false);
});

test("half a birthday is no birthday", () => {
  // A month with no day is not a date anybody can count down to, and storing
  // it would put a person in the birthday list with nothing to show.
  const data = profileUpdateData({ birthdayMonth: 9 });

  assert.equal(data.birthdayMonth, null);
  assert.equal(data.birthdayDay, null);
  assert.equal(data.birthdayYear, null);
});

test("clearing the birthday clears the year with it", () => {
  const data = profileUpdateData({
    birthdayMonth: null,
    birthdayDay: null,
    birthdayYear: null,
  });

  assert.equal(data.birthdayMonth, null);
  assert.equal(data.birthdayYear, null);
});

test("lastSeenAt becomes a Date, and null clears it", () => {
  const set = profileUpdateData({ lastSeenAt: "2026-08-27T10:00:00.000Z" });
  assert.ok(set.lastSeenAt instanceof Date);
  assert.equal(set.lastSeenAt.toISOString(), "2026-08-27T10:00:00.000Z");

  assert.equal(profileUpdateData({ lastSeenAt: null }).lastSeenAt, null);
});

test("29 February is storable, because it is a real birthday", () => {
  // Whether the day exists in a given year is the next-occurrence rule's
  // problem, not the schema's.
  const parsed = personProfileSchema.safeParse({
    birthdayMonth: 2,
    birthdayDay: 29,
    birthdayYear: 1996,
  });

  assert.equal(parsed.success, true);
});

test("impossible birthday parts are refused", () => {
  assert.equal(
    personProfileSchema.safeParse({ birthdayMonth: 13, birthdayDay: 1 }).success,
    false,
  );
  assert.equal(
    personProfileSchema.safeParse({ birthdayMonth: 1, birthdayDay: 32 }).success,
    false,
  );
});

test("a cadence is bounded at both ends", () => {
  // Zero would report somebody overdue every day; an unbounded one is a rhythm
  // nobody is ever overdue on, which is the same as having none.
  assert.equal(personProfileSchema.safeParse({ cadenceDays: 0 }).success, false);
  assert.equal(
    personProfileSchema.safeParse({ cadenceDays: 100000 }).success,
    false,
  );
  assert.equal(personProfileSchema.safeParse({ cadenceDays: 91 }).success, true);
  // Null is how a rhythm is switched off, and must stay allowed.
  assert.equal(personProfileSchema.safeParse({ cadenceDays: null }).success, true);
});

test("one update carries identity and profile together", () => {
  // The People editor changes a name and a birthday on one sheet; splitting
  // that into two writes would put two entries in the queue for one action.
  const parsed = updatePersonSchema.safeParse({
    name: "Jonas Brehm",
    nickname: "Jo",
    cadenceDays: 61,
    birthdayMonth: 2,
    birthdayDay: 29,
    archived: false,
  });

  assert.equal(parsed.success, true);
  assert.equal(parsed.data.nickname, "Jo");
  assert.equal(parsed.data.name, "Jonas Brehm");
});
