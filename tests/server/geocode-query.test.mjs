import assert from "node:assert/strict";
import test from "node:test";

import {
  geocodeKey,
  geocodeQuery,
  isStaleMiss,
} from "../../src/lib/geocode-query.ts";

test("the same city typed differently is one lookup", () => {
  // Two friends in Munich must not cost two requests to a rate-limited
  // geocoder, and must not end up as two pins on the map.
  assert.equal(geocodeKey("Munich", "DE"), geocodeKey(" munich ", "de"));
  assert.equal(geocodeKey("New  York"), geocodeKey("New York"));
});

test("a city with a country is a different place from one without", () => {
  // There is more than one Springfield, and the country is the only thing
  // separating them.
  assert.notEqual(geocodeKey("Springfield"), geocodeKey("Springfield", "US"));
});

test("only the city is ever sent to the geocoder", () => {
  // The design decision this enforces: the map answers "who is in this city",
  // which a centroid answers exactly as well as a street address would — and
  // a record of friends' addresses should not become a map of their doors.
  assert.equal(geocodeQuery("Munich", "DE"), "Munich, DE");
  assert.equal(geocodeQuery("Munich"), "Munich");
  assert.equal(geocodeQuery("  Munich  ", "  DE  "), "Munich, DE");
});

test("a resolved city is never looked up again", () => {
  // Centroids do not move, so a hit has no expiry at all.
  const hit = { latitude: 48.13, resolvedAt: new Date("2020-01-01") };
  assert.equal(isStaleMiss(hit, new Date("2030-01-01")), false);
});

test("a miss is retried, but not on every sync", () => {
  // It may have been a typo since fixed, or a geocoder having a bad day.
  const miss = { latitude: null, resolvedAt: new Date("2026-09-01T00:00:00Z") };

  assert.equal(isStaleMiss(miss, new Date("2026-09-03T00:00:00Z")), false);
  assert.equal(isStaleMiss(miss, new Date("2026-09-20T00:00:00Z")), true);
});
