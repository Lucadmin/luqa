import { db } from "@/lib/db";
import { geocodeKey, geocodeQuery, isStaleMiss } from "@/lib/geocode-query";

/**
 * Resolving a city to a point, once.
 *
 * Nominatim is free and needs no key, which is why it is here — and it is
 * rate-limited to one request a second and asks that heavy users cache, which
 * is why almost every call below never reaches it. A personal address book has
 * a few dozen distinct cities in it; after the first sync this is a database
 * read.
 *
 * Only ever a city, never a street. See `geocodeQuery`.
 */

const NOMINATIM = "https://nominatim.openstreetmap.org/search";

/// Nominatim's usage policy requires a User-Agent that identifies the
/// application and a way to reach whoever runs it.
const USER_AGENT =
  "Luqa/1.0 (personal life-tracking app; https://github.com/luqa-app)";

/// One request per second, as the policy asks. The gap is held across calls in
/// a single server instance, which is what a batch walks through.
const MIN_INTERVAL_MS = 1100;

/// How many cities one request will resolve. Small because each miss costs a
/// second of wall clock, and a serverless invocation has a ceiling.
export const GEOCODE_BATCH = 8;

let lastRequestAt = 0;

async function respectRateLimit(): Promise<void> {
  const wait = lastRequestAt + MIN_INTERVAL_MS - Date.now();
  if (wait > 0) await new Promise((resolve) => setTimeout(resolve, wait));
  lastRequestAt = Date.now();
}

export interface GeocodeResult {
  latitude: number | null;
  longitude: number | null;
  city: string | null;
  country: string | null;
}

/** Asks Nominatim. Returns a miss rather than throwing: a city that will not
 *  resolve is a place that lists without pinning, which is a state the map
 *  already has to handle. */
async function lookup(
  city: string,
  country: string | null,
): Promise<GeocodeResult> {
  const url = new URL(NOMINATIM);
  url.searchParams.set("q", geocodeQuery(city, country));
  url.searchParams.set("format", "jsonv2");
  url.searchParams.set("limit", "1");
  // Settlements only. Without this a city name that happens to match a shop
  // resolves to the shop.
  url.searchParams.set("featureType", "city");
  url.searchParams.set("addressdetails", "1");

  await respectRateLimit();

  try {
    const response = await fetch(url, {
      headers: { "User-Agent": USER_AGENT, "Accept-Language": "en" },
      signal: AbortSignal.timeout(8000),
    });
    if (!response.ok) return miss();

    const body = (await response.json()) as Array<{
      lat?: string;
      lon?: string;
      name?: string;
      address?: { country_code?: string };
    }>;
    const first = body[0];
    if (!first?.lat || !first?.lon) return miss();

    const latitude = Number(first.lat);
    const longitude = Number(first.lon);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return miss();

    return {
      latitude,
      longitude,
      city: first.name ?? null,
      country: first.address?.country_code?.toUpperCase() ?? null,
    };
  } catch {
    // A timeout, a DNS failure, a rate-limit rejection. None of them are worth
    // failing the request the user actually made.
    return miss();
  }
}

const miss = (): GeocodeResult => ({
  latitude: null,
  longitude: null,
  city: null,
  country: null,
});

/** The cached point for a city, looking it up only if nobody has. */
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

  const result = await lookup(city, country);
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
 * Pull rather than push: a place is usable the moment it is typed, and the
 * pin catches up. Doing this on the write path would make adding a city wait
 * on a rate-limited third party, and doing it in the background is not
 * something a serverless request can promise to finish.
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
      await tx.person.update({ where: { id: place.personId }, data: {} });
    });
    resolved += 1;
  }

  return { resolved, remaining: Math.max(0, pending.length - limit) };
}
