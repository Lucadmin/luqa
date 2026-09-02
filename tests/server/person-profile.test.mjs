import assert from "node:assert/strict";
import test from "node:test";

import {
  placeWriteData,
  profileUpdateData,
  touchData,
} from "../../src/lib/person-profile.ts";
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
    personProfileSchema.safeParse({ birthdayMonth: 13, birthdayDay: 1 })
      .success,
    false,
  );
  assert.equal(
    personProfileSchema.safeParse({ birthdayMonth: 1, birthdayDay: 32 })
      .success,
    false,
  );
});

test("a cadence is bounded at both ends", () => {
  // Zero would report somebody overdue every day; an unbounded one is a rhythm
  // nobody is ever overdue on, which is the same as having none.
  assert.equal(
    personProfileSchema.safeParse({ cadenceDays: 0 }).success,
    false,
  );
  assert.equal(
    personProfileSchema.safeParse({ cadenceDays: 100000 }).success,
    false,
  );
  assert.equal(
    personProfileSchema.safeParse({ cadenceDays: 91 }).success,
    true,
  );
  // Null is how a rhythm is switched off, and must stay allowed.
  assert.equal(
    personProfileSchema.safeParse({ cadenceDays: null }).success,
    true,
  );
});

test("closeness is an explicit coarse level, not a computed score", () => {
  assert.equal(personProfileSchema.safeParse({ closeness: 1 }).success, true);
  assert.equal(personProfileSchema.safeParse({ closeness: 4 }).success, true);
  assert.equal(personProfileSchema.safeParse({ closeness: null }).success, true);
  assert.equal(personProfileSchema.safeParse({ closeness: 0 }).success, false);
  assert.equal(personProfileSchema.safeParse({ closeness: 5 }).success, false);
  assert.deepEqual(profileUpdateData({ closeness: 3 }), { closeness: 3 });
});

test("person-to-person links carry a named endpoint and coarse level", () => {
  const parsed = updatePersonSchema.safeParse({
    connections: [
      { personId: "person-b", closeness: 3 },
      { personId: "person-c", closeness: 1 },
    ],
  });

  assert.equal(parsed.success, true);
  assert.equal(parsed.data.connections.length, 2);
  assert.equal(
    updatePersonSchema.safeParse({
      connections: [{ personId: "person-b", closeness: 9 }],
    }).success,
    false,
  );
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

// The invariant the whole People feature rests on. Places, notes and gift
// ideas ride inside the person rather than syncing on their own, and the delta
// feed finds changed rows by ordering on `updatedAt`. A child written without
// a real bump to the parent is a change no second device ever hears about —
// and nothing looks broken, because the write succeeds and every direct read
// shows it.

test("touching a person carries a timestamp, not an empty update", () => {
  // This is the regression. `data: {}` reads like it would move `@updatedAt`
  // and does not: Prisma treats an empty update as a no-op, so the row never
  // enters the delta feed. The timestamp has to be written explicitly.
  const data = touchData(new Date("2026-09-01T10:00:00.000Z"));

  assert.equal(Object.keys(data).length > 0, true);
  assert.ok(data.updatedAt instanceof Date);
  assert.equal(data.updatedAt.toISOString(), "2026-09-01T10:00:00.000Z");
});

test("a touch moves the row forward", () => {
  const before = new Date("2026-09-01T10:00:00.000Z");
  const data = touchData(new Date("2026-09-01T10:00:01.000Z"));

  assert.equal(data.updatedAt.getTime() > before.getTime(), true);
});

// Adding a city: whether anybody chose one is the whole difference between a
// place that pins on write and a place the geocoding batch has to guess at.

const munich = {
  id: 2867714,
  name: "Munich",
  admin1: "Bavaria",
  countryCode: "DE",
  timezone: "Europe/Berlin",
  latitude: 48.13743,
  longitude: 11.57549,
};

test("a chosen city arrives already on the map", () => {
  // The point comes from the server's own cache of the city the owner picked,
  // never from the client, and it is written on the way in — so there is no
  // window where a place the owner just chose sits unlocated.
  const data = placeWriteData({ label: "Home", city: "munchen" }, munich);

  assert.equal(data.cityId, 2867714);
  assert.equal(data.latitude, 48.13743);
  assert.equal(data.longitude, 11.57549);
  assert.equal(data.timezone, "Europe/Berlin");
  // The canonical name wins over what was typed: two people in this city have
  // to read the same way in a list.
  assert.equal(data.city, "Munich");
  assert.equal(data.region, "Bavaria");
  assert.equal(data.country, "DE");
});

test("a city that was only typed lands unlocated, as it always did", () => {
  // Offline, or imported from a contact book. The place lists immediately and
  // the batch puts a point on it later.
  const data = placeWriteData({ label: "Home", city: "Munich" }, null);

  assert.equal(data.city, "Munich");
  assert.equal(data.cityId, null);
  assert.equal(data.latitude, null);
  assert.equal(data.longitude, null);
  assert.equal(data.timezone, null);
});

test("an id the server cannot resolve degrades instead of failing", () => {
  // A client holding an id for longer than the cache held the row resolves to
  // nothing. Refusing the write would lose a city over a cache miss; this
  // keeps the name and lets the batch sort it out.
  const data = placeWriteData({ label: "Home", city: "Munich" }, null);

  assert.equal(data.city, "Munich");
  assert.equal(data.cityId, null);
});

test("what the client said about the region survives when nobody chose", () => {
  // A contact book import has a region and a country and no id at all, and
  // dropping them would make the row worse than what arrived.
  const data = placeWriteData(
    { label: "Parents", city: "Cambridge", region: "England", country: "GB" },
    null,
  );

  assert.equal(data.region, "England");
  assert.equal(data.country, "GB");
});
