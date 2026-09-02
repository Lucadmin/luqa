/**
 * The profile half of a person, as arithmetic on plain values.
 *
 * Kept apart from the queries — the same reason `sync-cursor.ts` is kept apart
 * from `sync.ts` — so the one rule that is easy to get wrong here can be
 * reasoned about, and tested, without a database anywhere near it.
 */

/**
 * What a "this row changed" write has to carry.
 *
 * An empty `data` is a no-op: Prisma issues nothing, and `@updatedAt` does not
 * move. That is the failure the whole People feature rests on not happening —
 * places, notes and gift ideas ride inside the person, and the delta feed finds
 * changed rows by ordering on `updatedAt`, so a child written without a real
 * bump is a change no device ever hears about. Nothing looks broken: the write
 * succeeds, direct reads show it, and only the second device is wrong.
 *
 * So the timestamp is set explicitly rather than left to `@updatedAt`, and it
 * lives here where a test can assert it is not empty without a database.
 */
export function touchData(now: Date = new Date()): { updatedAt: Date } {
  return { updatedAt: now };
}

export interface PersonProfilePatch {
  nickname?: string | null;
  photoUrl?: string | null;
  birthdayYear?: number | null;
  birthdayMonth?: number | null;
  birthdayDay?: number | null;
  cadenceDays?: number | null;
  closeness?: number | null;
  lastSeenAt?: string | null;
}

/** The profile columns as plain scalars, so one translation serves both a
 *  create and an update. */
export interface PersonProfileFields {
  nickname?: string | null;
  photoUrl?: string | null;
  birthdayYear?: number | null;
  birthdayMonth?: number | null;
  birthdayDay?: number | null;
  cadenceDays?: number | null;
  closeness?: number | null;
  lastSeenAt?: Date | null;
}

/** Translates the profile half of a request body into columns.
 *
 *  Birthday is written as a unit: a body that sets the month and day clears a
 *  stale year rather than leaving 14 March 1994 half-updated into 3 April 1994.
 *  A body that mentions no birthday field at all leaves the birthday alone. */
export function profileUpdateData(
  patch: PersonProfilePatch,
): PersonProfileFields {
  const data: PersonProfileFields = {};
  if (patch.nickname !== undefined) data.nickname = patch.nickname;
  if (patch.photoUrl !== undefined) data.photoUrl = patch.photoUrl;

  const touchesBirthday =
    patch.birthdayMonth !== undefined ||
    patch.birthdayDay !== undefined ||
    patch.birthdayYear !== undefined;
  if (touchesBirthday) {
    const month = patch.birthdayMonth ?? null;
    const day = patch.birthdayDay ?? null;
    // A month without a day, or a day without a month, is not a birthday.
    const complete = month !== null && day !== null;
    data.birthdayMonth = complete ? month : null;
    data.birthdayDay = complete ? day : null;
    data.birthdayYear = complete ? (patch.birthdayYear ?? null) : null;
  }

  if (patch.cadenceDays !== undefined) data.cadenceDays = patch.cadenceDays;
  if (patch.closeness !== undefined) data.closeness = patch.closeness;
  if (patch.lastSeenAt !== undefined) {
    data.lastSeenAt = patch.lastSeenAt ? new Date(patch.lastSeenAt) : null;
  }
  return data;
}

/** What arrived on the wire for a place. Only the fields the merge below
 *  reads; `latitude` and `longitude` are deliberately not among them, because
 *  the client never sends where a city is. */
export interface PersonPlacePatch {
  label: string;
  city: string;
  region?: string | null;
  country?: string | null;
  address?: string | null;
}

/** The city the owner chose, as the server read it back out of its own cache.
 *  Null when nothing was chosen, or when the id meant nothing to us. */
export interface ChosenCity {
  id: number;
  name: string;
  admin1: string | null;
  countryCode: string | null;
  timezone: string | null;
  latitude: number;
  longitude: number;
}

export interface PersonPlaceFields {
  label: string;
  city: string;
  region: string | null;
  country: string | null;
  address: string | null;
  cityId: number | null;
  timezone: string | null;
  latitude: number | null;
  longitude: number | null;
}

/**
 * The columns a place is written with.
 *
 * The whole difference between the two ways of adding a city lives here. With
 * a [chosen] city the row is complete on arrival — canonical name, region,
 * country, zone and centroid — and the geocoding batch never sees it. Without
 * one, the typed name is taken as given and the point stays null, which is a
 * place that lists but does not yet pin.
 *
 * The canonical name wins over the typed one only when something was chosen:
 * that is what makes two people in the same city read the same way in a list,
 * and there is nothing to be canonical about when nobody picked.
 */
export function placeWriteData(
  patch: PersonPlacePatch,
  chosen: ChosenCity | null,
): PersonPlaceFields {
  return {
    label: patch.label,
    // An empty canonical name would be worse than the typed one, so it has to
    // be non-empty to win.
    city: chosen?.name || patch.city,
    region: chosen?.admin1 ?? patch.region ?? null,
    country: chosen?.countryCode ?? patch.country ?? null,
    address: patch.address ?? null,
    cityId: chosen?.id ?? null,
    timezone: chosen?.timezone ?? null,
    latitude: chosen?.latitude ?? null,
    longitude: chosen?.longitude ?? null,
  };
}
