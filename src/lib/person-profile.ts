/**
 * The profile half of a person, as arithmetic on plain values.
 *
 * Kept apart from the queries — the same reason `sync-cursor.ts` is kept apart
 * from `sync.ts` — so the one rule that is easy to get wrong here can be
 * reasoned about, and tested, without a database anywhere near it.
 */

export interface PersonProfilePatch {
  nickname?: string | null;
  photoUrl?: string | null;
  birthdayYear?: number | null;
  birthdayMonth?: number | null;
  birthdayDay?: number | null;
  cadenceDays?: number | null;
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
  if (patch.lastSeenAt !== undefined) {
    data.lastSeenAt = patch.lastSeenAt ? new Date(patch.lastSeenAt) : null;
  }
  return data;
}

