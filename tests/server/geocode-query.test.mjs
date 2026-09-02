import assert from "node:assert/strict";
import test from "node:test";

import {
  bestCandidate,
  geocodeKey,
  geocodeQuery,
  isStaleMiss,
  isStaleSearch,
} from "../../src/lib/geocode-query.ts";

/** A candidate with only the fields the ranking looks at. */
const city = (name, population, featureCode = "PPL", id = population) => ({
  id,
  name,
  admin1: null,
  country: null,
  countryCode: null,
  latitude: 0,
  longitude: 0,
  timezone: null,
  population,
  featureCode,
});

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

test("a typed prefix is one search however it was typed", () => {
  // The same key serves the search cache: every prefix a second person types
  // towards "Cambridge" is one the first person already paid for.
  assert.equal(geocodeKey(" Cam "), geocodeKey("cam"));

  // A country-narrowed search is its own question, though — "Cambridge" in the
  // US must not be served the unnarrowed list.
  assert.notEqual(geocodeKey("Cambridge"), geocodeKey("Cambridge", "US"));
});

test("a name nobody picked resolves to the biggest city of that name", () => {
  // Only names that were typed rather than chosen reach this: a place added
  // through the picker carries its city's id. Guessing beats an empty map, and
  // the biggest is the guess a person would make too.
  const best = bestCandidate([
    city("Springfield", 114000),
    city("Springfield", 169000),
    city("Springfield", 60000),
  ]);
  assert.equal(best.population, 169000);
});

test("a capital outranks a village nobody has counted", () => {
  // Population is missing often enough that it cannot be the only rule: with
  // nothing to compare, the capital is the better guess.
  const best = bestCandidate([
    city("Vaduz", null, "PPL", 1),
    city("Vaduz", null, "PPLC", 2),
  ]);
  assert.equal(best.id, 2);
});

test("nothing found is nothing chosen", () => {
  // The caller stores this as a miss, which is what stops a misspelt city
  // being looked up again on every sync.
  assert.equal(bestCandidate([]), null);
});

test("a search is reused for a month, then asked again", () => {
  // Longer than a miss: the set of cities called "Cambridge" is not going to
  // change this week. Not for ever: new places do appear in the source data.
  const searched = { searchedAt: new Date("2026-09-01T00:00:00Z") };
  assert.equal(
    isStaleSearch(searched, new Date("2026-09-20T00:00:00Z")),
    false,
  );
  assert.equal(isStaleSearch(searched, new Date("2026-10-20T00:00:00Z")), true);
});
