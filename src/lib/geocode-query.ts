/**
 * Turning a typed city into a cache key and a geocoder query.
 *
 * Kept apart from the network and the database — the same reason
 * `sync-cursor.ts` is — so the normalisation can be tested without either.
 */

/** The cache key for a city. Two people who typed "Munich" and " munich "
 *  must not cost two lookups, and must not produce two pins. */
export function geocodeKey(city: string, country?: string | null): string {
  const normalise = (value: string) =>
    value
      .trim()
      .toLowerCase()
      // Collapse internal whitespace so "New  York" and "New York" agree.
      .replace(/\s+/g, " ");
  const place = normalise(city);
  const region = country ? normalise(country) : "";
  return region ? `${place}|${region}` : place;
}

/** What gets sent to the geocoder: the city and, when known, the country.
 *  Deliberately never the street address — the map answers "who is in this
 *  city", and a city centroid answers it exactly as well without turning a
 *  record of friends' addresses into a map of their front doors. */
export function geocodeQuery(city: string, country?: string | null): string {
  const place = city.trim();
  const region = country?.trim();
  return region ? `${place}, ${region}` : place;
}

/** How long a miss is trusted before it is worth asking again.
 *
 *  A hit never expires: city centroids do not move. A miss might have been a
 *  typo the user has since fixed, or a geocoder having a bad day, so it is
 *  retried — just not on every sync. */
export const MISS_RETRY_MS = 7 * 24 * 60 * 60 * 1000;

export function isStaleMiss(
  entry: { latitude: number | null; resolvedAt: Date },
  now: Date,
): boolean {
  if (entry.latitude !== null) return false;
  return now.getTime() - entry.resolvedAt.getTime() > MISS_RETRY_MS;
}
