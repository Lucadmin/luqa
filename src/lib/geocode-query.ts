/**
 * Turning a typed city into a cache key and a geocoder query, and turning a
 * list of candidates into the one a city name most likely meant.
 *
 * Kept apart from the network and the database — the same reason
 * `sync-cursor.ts` is — so the normalisation and the ranking can be tested
 * without either.
 */

/** Trimmed, lower-cased, internal whitespace collapsed, so "New  York" and
 *  "New York" agree. */
function normalise(value: string): string {
  return value.trim().toLowerCase().replace(/\s+/g, " ");
}

/** The cache key for a city, and for a search-as-you-type query.
 *
 *  Two people who typed "Munich" and " munich " must not cost two lookups, and
 *  must not produce two pins. The same holds a keystroke at a time: every
 *  prefix a second person types towards "Cambridge" is one the first person
 *  already paid for. */
export function geocodeKey(city: string, country?: string | null): string {
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

/** A settlement the geocoder knows about. The fields that are not coordinates
 *  are what let a person tell two Springfields apart. */
export interface CityCandidate {
  /** The GeoNames id. Stable, which is the whole reason a place stores it:
   *  two people in Munich share a pin because they share this number, not
   *  because their city strings happen to match. */
  id: number;
  name: string;
  /** The first-level administrative area — the state, province or Land. The
   *  single most useful thing for telling same-named cities apart. */
  admin1: string | null;
  country: string | null;
  countryCode: string | null;
  latitude: number;
  longitude: number;
  timezone: string | null;
  population: number | null;
  /** The GeoNames feature code: PPLC for a national capital, PPLA for a
   *  first-order administrative capital, PPL for an ordinary settlement. */
  featureCode: string | null;
}

/** Capitals outrank ordinary settlements of the same size. Lower is better. */
function rank(featureCode: string | null): number {
  switch (featureCode) {
    case "PPLC":
      return 0;
    case "PPLA":
      return 1;
    case "PPLA2":
      return 2;
    default:
      return 3;
  }
}

/**
 * The candidate a bare city name most likely meant.
 *
 * Only for names nobody picked from a list: a place added through the picker
 * carries the chosen city's id and never comes near this. That leaves cities
 * typed offline and cities imported from a contact book, where guessing beats
 * leaving the map empty — and the biggest settlement of the name is the guess
 * a person would make too.
 */
export function bestCandidate(
  candidates: readonly CityCandidate[],
): CityCandidate | null {
  let best: CityCandidate | null = null;
  for (const candidate of candidates) {
    if (best === null) {
      best = candidate;
      continue;
    }
    const population = candidate.population ?? 0;
    const bestPopulation = best.population ?? 0;
    if (population > bestPopulation) best = candidate;
    // A capital and a village of unknown size both read as population 0, and
    // between those the capital is the better guess.
    else if (
      population === bestPopulation &&
      rank(candidate.featureCode) < rank(best.featureCode)
    ) {
      best = candidate;
    }
  }
  return best;
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

/** How long a search result list is reused before it is asked for again.
 *
 *  Longer than a miss and shorter than for ever: the set of cities called
 *  "Cambridge" is not going to change this month, but a new place appearing in
 *  the source data should eventually show up. */
export const SEARCH_TTL_MS = 30 * 24 * 60 * 60 * 1000;

export function isStaleSearch(entry: { searchedAt: Date }, now: Date): boolean {
  return now.getTime() - entry.searchedAt.getTime() > SEARCH_TTL_MS;
}
