import { db } from "@/lib/db";
import {
  bestCandidate,
  geocodeKey,
  geocodeQuery,
  isStaleMiss,
  isStaleSearch,
  type CityCandidate,
} from "@/lib/geocode-query";
import { touchPerson } from "@/lib/server/people";

/**
 * Finding a city, and resolving one to a point.
 *
 * Open-Meteo's geocoding API is free, needs no key, and — unlike Nominatim,
 * which this used to call — is built for search-as-you-type rather than
 * rate-limited to one request a second. It is GeoNames data, so every result
 * carries a stable id, its first-level administrative area, its population and
 * its time zone: exactly the fields a person needs to tell two Springfields
 * apart, and exactly the id that lets two places be recognised as the same
 * city later.
 *
 * Almost every call below never reaches it. A personal address book has a few
 * dozen distinct cities in it, and the same handful of prefixes are typed over
 * and over; after the first time, this is a database read.
 *
 * Only ever a city, never a street. See `geocodeQuery`.
 */

const OPEN_METEO = "https://geocoding-api.open-meteo.com/v1";

/// Identifies the application, as a courtesy to a free service.
const USER_AGENT =
  "Luqa/1.0 (personal life-tracking app; https://github.com/luqa-app)";

/// How many candidates a search offers. Enough that the city somebody meant is
/// in the list, few enough that the list is still readable on a phone.
export const SEARCH_LIMIT = 10;

/// How many typed cities one geocoding request will resolve. Larger than it
/// was under Nominatim, where each miss cost a second of wall clock.
export const GEOCODE_BATCH = 25;

interface OpenMeteoResult {
  id?: number;
  name?: string;
  latitude?: number;
  longitude?: number;
  admin1?: string;
  country?: string;
  country_code?: string;
  timezone?: string;
  population?: number;
  feature_code?: string;
}

/** Everything the geocoder said, in our shape.
 *
 *  Two things are dropped. Anything without an id or a usable point, which
 *  cannot be stored, chosen or plotted. And anything that is not a settlement:
 *  GeoNames prefixes populated places with `PPL`, and without this filter
 *  searching "Munich" offers Munich Airport, and "Springfield" offers
 *  Springfield Park. This is a city picker; a city is what it should list. */
function toCandidates(results: readonly OpenMeteoResult[]): CityCandidate[] {
  const candidates: CityCandidate[] = [];
  for (const result of results) {
    if (typeof result.id !== "number") continue;
    const { latitude, longitude } = result;
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) continue;
    // A missing code is kept: it is unknown, not disqualifying.
    if (result.feature_code && !result.feature_code.startsWith("PPL")) continue;
    candidates.push({
      id: result.id,
      name: result.name ?? "",
      admin1: result.admin1 || null,
      country: result.country || null,
      countryCode: result.country_code?.toUpperCase() || null,
      latitude: latitude as number,
      longitude: longitude as number,
      timezone: result.timezone || null,
      population: result.population ?? null,
      featureCode: result.feature_code || null,
    });
  }
  return candidates;
}

/** Asks Open-Meteo. Returns an empty list rather than throwing: a search that
 *  found nothing and a search that could not be made both end with the sheet
 *  offering the typed name, which is a state it already has to handle. */
async function ask(
  path: string,
  params: Record<string, string>,
): Promise<CityCandidate[]> {
  const url = new URL(`${OPEN_METEO}${path}`);
  for (const [key, value] of Object.entries(params)) {
    url.searchParams.set(key, value);
  }
  url.searchParams.set("format", "json");
  url.searchParams.set("language", "en");

  try {
    const response = await fetch(url, {
      headers: { "User-Agent": USER_AGENT },
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) return [];
    // `/search` answers with a `results` array; `/get` answers with the city
    // itself, unwrapped. Handling both here keeps the difference from leaking
    // into the two callers.
    const body = (await response.json()) as
      { results?: OpenMeteoResult[] } | OpenMeteoResult;
    const results =
      "results" in body ? (body.results ?? []) : [body as OpenMeteoResult];
    return toCandidates(results);
  } catch {
    // A timeout, a DNS failure, a service having a bad day. None of them are
    // worth failing the request the user actually made.
    return [];
  }
}

/** Writes what the geocoder said into the shared city table, so that choosing
 *  one of these later costs a primary-key read and no network at all. */
async function remember(candidates: readonly CityCandidate[]): Promise<void> {
  const now = new Date();
  await Promise.all(
    candidates.map((city) =>
      db.geoCity.upsert({
        where: { geonameId: city.id },
        create: {
          geonameId: city.id,
          name: city.name,
          admin1: city.admin1,
          country: city.country,
          countryCode: city.countryCode,
          latitude: city.latitude,
          longitude: city.longitude,
          timezone: city.timezone,
          population: city.population,
          featureCode: city.featureCode,
          fetchedAt: now,
        },
        update: {
          name: city.name,
          admin1: city.admin1,
          country: city.country,
          countryCode: city.countryCode,
          latitude: city.latitude,
          longitude: city.longitude,
          timezone: city.timezone,
          population: city.population,
          featureCode: city.featureCode,
          fetchedAt: now,
        },
      }),
    ),
  );
}

function fromRow(row: {
  geonameId: number;
  name: string;
  admin1: string | null;
  country: string | null;
  countryCode: string | null;
  latitude: number;
  longitude: number;
  timezone: string | null;
  population: number | null;
  featureCode: string | null;
}): CityCandidate {
  return {
    id: row.geonameId,
    name: row.name,
    admin1: row.admin1,
    country: row.country,
    countryCode: row.countryCode,
    latitude: row.latitude,
    longitude: row.longitude,
    timezone: row.timezone,
    population: row.population,
    featureCode: row.featureCode,
  };
}

/**
 * The cities a query might mean, best match first.
 *
 * Cached by the normalised query, because a person typing "cambridge" types
 * nine prefixes on the way there and the next person types the same nine.
 *
 * [countryCode] narrows to one country, for the backfill path where a stored
 * place already says which. It is a query parameter rather than something
 * appended to the name: "Munich, DE" matches nothing at all, while
 * `countryCode=DE` is how this geocoder is actually asked.
 */
export async function searchCities(
  query: string,
  limit = SEARCH_LIMIT,
  countryCode: string | null = null,
): Promise<CityCandidate[]> {
  const trimmed = query.trim();
  if (trimmed.length < 2) return [];

  // The country is part of the key, or "Cambridge" narrowed to the US would
  // be served the unnarrowed list the next time anybody types it.
  const key = geocodeKey(trimmed, countryCode);
  const cached = await db.geoSearch.findUnique({ where: { query: key } });

  if (cached && !isStaleSearch(cached, new Date())) {
    const rows = await db.geoCity.findMany({
      where: { geonameId: { in: cached.geonameIds } },
    });
    const byId = new Map(rows.map((row) => [row.geonameId, fromRow(row)]));
    // The geocoder's order, not the database's: it ranked these better than
    // any ordering we could ask Postgres for.
    const ordered = cached.geonameIds
      .map((id) => byId.get(id))
      .filter((city): city is CityCandidate => city !== undefined);
    // Only trust the cached list if every id in it is still there. A pruned
    // city would otherwise silently drop out of the results for a month.
    if (ordered.length === cached.geonameIds.length)
      return ordered.slice(0, limit);
  }

  const candidates = await ask("/search", {
    name: trimmed,
    count: String(limit),
    ...(countryCode ? { countryCode } : {}),
  });
  if (candidates.length === 0) return [];

  await remember(candidates);
  await db.geoSearch.upsert({
    where: { query: key },
    create: {
      query: key,
      geonameIds: candidates.map((city) => city.id),
      searchedAt: new Date(),
    },
    update: {
      geonameIds: candidates.map((city) => city.id),
      searchedAt: new Date(),
    },
  });
  return candidates;
}

/**
 * A city by the id somebody chose, without going anywhere near the network in
 * the normal case.
 *
 * The search that offered the id already wrote the row, so this is a
 * primary-key read. The fetch is only for the odd case of a client that held
 * an id longer than the cache did.
 */
export async function resolveCityId(
  cityId: number,
): Promise<CityCandidate | null> {
  const row = await db.geoCity.findUnique({ where: { geonameId: cityId } });
  if (row) return fromRow(row);

  const [candidate] = await ask("/get", { id: String(cityId) });
  if (!candidate) return null;
  await remember([candidate]);
  return candidate;
}

export interface GeocodeResult {
  latitude: number | null;
  longitude: number | null;
  city: string | null;
  country: string | null;
}

const miss = (): GeocodeResult => ({
  latitude: null,
  longitude: null,
  city: null,
  country: null,
});

/** Whether a stored country is an ISO alpha-2 code ("DE") rather than a
 *  written-out name ("Germany"). Both turn up: this app writes codes, a
 *  contact book import writes whatever the contact book had. */
function isCountryCode(country: string | null): country is string {
  return country !== null && /^[A-Za-z]{2}$/.test(country.trim());
}

/**
 * The cached point for a typed city name, looking it up only if nobody has.
 *
 * This is the path for names nobody picked: typed offline, or imported from a
 * contact book. There is no one to ask which Springfield was meant, so
 * `bestCandidate` guesses — the biggest one — because a pin in the wrong
 * Springfield is still better than a person who never appears on the map, and
 * the owner can fix it by picking properly.
 */
export async function resolveCity(
  city: string,
  country: string | null,
): Promise<GeocodeResult> {
  const key = geocodeKey(city, country);
  const cached = await db.geocodeCache.findUnique({ where: { query: key } });

  if (cached && !isStaleMiss(cached, new Date())) {
    return {
      latitude: cached.latitude,
      longitude: cached.longitude,
      city: cached.city,
      country: cached.country,
    };
  }

  // A stored country is either an ISO code, which this geocoder takes as a
  // filter, or a written-out name, which it only understands after a comma.
  // Sending a code after a comma matches nothing at all, which would have
  // quietly stopped every imported place from ever pinning.
  const code = isCountryCode(country) ? country.trim().toUpperCase() : null;
  const candidates = await searchCities(
    code ? city.trim() : geocodeQuery(city, country),
    SEARCH_LIMIT,
    code,
  );
  const best = bestCandidate(candidates);
  const result: GeocodeResult = best
    ? {
        latitude: best.latitude,
        longitude: best.longitude,
        city: best.name,
        country: best.countryCode,
      }
    : miss();

  // Misses are stored too, with null coordinates, so a misspelt city is not
  // looked up again on every sync.
  await db.geocodeCache.upsert({
    where: { query: key },
    create: { query: key, ...result, resolvedAt: new Date() },
    update: { ...result, resolvedAt: new Date() },
  });
  return result;
}

/**
 * Puts coordinates on the user's places that do not have any yet.
 *
 * Only typed cities end up here. A place added through the picker arrives with
 * its point already on it, because the id it carries resolves from the
 * database on the write path.
 *
 * Pull rather than push, still: a typed city is usable the moment it is typed,
 * and the pin catches up. Doing this on the write path would make adding a
 * city wait on a third party, and doing it in the background is not something
 * a serverless request can promise to finish.
 *
 * Returns how many places were given a point, so the client knows whether the
 * map is worth re-reading.
 */
export async function geocodePendingPlaces(
  userId: string,
  limit = GEOCODE_BATCH,
): Promise<{ resolved: number; remaining: number }> {
  const pending = await db.personPlace.findMany({
    where: { person: { userId, deletedAt: null }, latitude: null },
    orderBy: { createdAt: "asc" },
    select: { id: true, personId: true, city: true, country: true },
  });

  let resolved = 0;
  // Distinct cities, not distinct places: two friends in Munich are one
  // lookup, and the second is answered from the row the first one wrote.
  for (const place of pending.slice(0, limit)) {
    const point = await resolveCity(place.city, place.country);
    if (point.latitude === null || point.longitude === null) continue;

    await db.$transaction(async (tx) => {
      await tx.personPlace.update({
        where: { id: place.id },
        data: {
          latitude: point.latitude,
          longitude: point.longitude,
          country: place.country ?? point.country,
        },
      });
      // The place lives inside its person on the wire, so the person is what
      // has to look changed for any device to hear about the new pin.
      await touchPerson(tx, place.personId);
    });
    resolved += 1;
  }

  return { resolved, remaining: Math.max(0, pending.length - limit) };
}
