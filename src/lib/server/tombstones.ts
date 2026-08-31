import { dbWithDeleted } from "@/lib/db";

/**
 * Re-adding something you deleted gives you the original back.
 *
 * Deleting a row now leaves it in place with a `deletedAt`, and the unique
 * keys on these tables — a person's name, a gym's code — do not care whether
 * a row is deleted. So creating "Mira" again after deleting "Mira" would
 * collide with a row nobody can see.
 *
 * Reviving is the better answer anyway. The user's mental model is that they
 * are adding Mira, not a second Mira, and every bill that ever pointed at her
 * still does. A fresh row would strand all of it.
 *
 * Each helper revives a deleted row and returns it, or returns null when
 * nothing deleted is in the way. Callers keep their own handling of a live
 * duplicate — the browser refuses one, a phone answers with the row it found.
 */

export async function reviveDeletedPerson(userId: string, name: string) {
  const existing = await dbWithDeleted.person.findFirst({
    where: { userId, name },
  });
  if (!existing?.deletedAt) return null;
  return dbWithDeleted.person.update({
    where: { id: existing.id },
    // Deleted and archived are different states, and coming back should not
    // silently leave someone hidden from every list.
    data: { deletedAt: null, archivedAt: null },
  });
}

export async function reviveDeletedGroup(userId: string, name: string) {
  const existing = await dbWithDeleted.personGroup.findFirst({
    where: { userId, name },
    include: { members: true },
  });
  if (!existing?.deletedAt) return null;
  return dbWithDeleted.personGroup.update({
    where: { id: existing.id },
    data: { deletedAt: null, archivedAt: null },
    include: { members: true },
  });
}

export async function reviveDeletedGymLocation(
  userId: string,
  code: string,
  id?: string,
) {
  const existing = await dbWithDeleted.gymLocation.findFirst({
    where: { userId, OR: [{ code }, ...(id ? [{ id }] : [])] },
  });
  if (!existing?.deletedAt) return null;
  return dbWithDeleted.gymLocation.update({
    where: { id: existing.id },
    data: { deletedAt: null, archivedAt: null },
  });
}

export async function reviveDeletedCategory(userId: string, name: string) {
  const existing = await dbWithDeleted.category.findFirst({
    where: { userId, name: { equals: name, mode: "insensitive" } },
  });
  if (!existing?.deletedAt) return null;
  return dbWithDeleted.category.update({
    where: { id: existing.id },
    data: { deletedAt: null, archived: false },
  });
}

/**
 * Brings back any of these exercises that were deleted, so the caller's own
 * "which of these already exist" pass sees them.
 *
 * Exercises are created in bulk from whatever a workout mentions, so there is
 * no single name to claim — the whole batch is reconciled at once.
 */
export async function reviveExercises(userId: string, names: string[]) {
  if (names.length === 0) return;
  await dbWithDeleted.exercise.updateMany({
    where: {
      userId,
      name: { in: names },
      deletedAt: { not: null },
      // A merged row is an alias, not an independently deleted exercise. It
      // stays retired so the old spelling can keep redirecting to its target.
      mergedIntoId: null,
    },
    data: { deletedAt: null, archivedAt: null },
  });
}
