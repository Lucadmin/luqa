import type { Prisma } from "@/generated/prisma/client";
import { type DbTransaction, db } from "@/lib/db";
import { toPersonDTO } from "@/lib/serializers";
import type { PersonDTO } from "@/lib/types";
export { profileUpdateData } from "@/lib/person-profile";
import {
  type PersonProfilePatch,
  profileUpdateData,
  touchData,
} from "@/lib/person-profile";
import { claimMoneyId } from "@/lib/server/money";
import { reviveDeletedPerson } from "@/lib/server/tombstones";

/**
 * Everything that writes a person, in one place.
 *
 * The People tab and Money's split-defaults editor are two views of one row,
 * so there is one module where a rename happens and one place that knows the
 * rules. Routes validate and authorise; the decisions live here.
 */

/** The children are part of the row on the wire, so every read that produces a
 *  DTO includes them. Notes are newest-first and gifts oldest-first, because
 *  that is the order each list is read in. */
export const personInclude = {
  places: { orderBy: [{ isPrimary: "desc" }, { createdAt: "asc" }] },
  channels: { orderBy: { createdAt: "asc" } },
  notes: { orderBy: { createdAt: "desc" } },
  gifts: { orderBy: { createdAt: "asc" } },
} satisfies Prisma.PersonInclude;

/**
 * Marks the parent person as changed.
 *
 * The timestamp is written explicitly. `data: {}` looks like it would move
 * `@updatedAt` and does not — Prisma treats an empty update as a no-op, so the
 * row never enters the delta feed and the child write reaches no other device.
 * See {@link touchData}.
 *
 * **This is the invariant the whole feature rests on.** Places, notes, gifts
 * and channels are not sync collections of their own — they ride inside
 * `PersonDTO`, and the delta feed finds changed rows by ordering on
 * `Person.updatedAt`. A note written without touching the parent is a note no
 * phone ever hears about: it is on the server, it is in every direct read, and
 * it never reaches the device. Nothing about it looks broken until somebody
 * notices a note missing on their other phone weeks later.
 *
 * So every child write goes through {@link writeChild}, which calls this in
 * the same transaction. Nothing writes a child table directly.
 */
export async function touchPerson(
  tx: DbTransaction,
  personId: string,
): Promise<void> {
  await tx.person.update({ where: { id: personId }, data: touchData() });
}

/** Runs a child-row write and bumps the parent, atomically. The only
 *  sanctioned way to write a person's children. */
export async function writeChild<T>(
  personId: string,
  write: (tx: DbTransaction) => Promise<T>,
): Promise<PersonDTO> {
  return db.$transaction(async (tx) => {
    await write(tx);
    await touchPerson(tx, personId);
    const person = await tx.person.findUniqueOrThrow({
      where: { id: personId },
      include: personInclude,
    });
    return toPersonDTO(person);
  });
}

/** The person, or null when they are not this user's. Every route that takes
 *  an id starts here: an id from a phone is a claim, not a fact. */
export async function findPerson(userId: string, id: string) {
  return db.person.findFirst({
    where: { id, userId },
    include: personInclude,
  });
}

export async function requireOwnedPerson(userId: string, id: string) {
  const person = await db.person.findFirst({
    where: { id, userId },
    select: { id: true },
  });
  return person !== null;
}

export async function listPeople(userId: string): Promise<PersonDTO[]> {
  const people = await db.person.findMany({
    where: { userId },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
    include: personInclude,
  });
  return people.map(toPersonDTO);
}

// ---------------------------------------------------------------- scalars

export type { PersonProfileFields, PersonProfilePatch } from "@/lib/person-profile";

export async function updatePersonRow(
  id: string,
  data: Prisma.PersonUpdateInput,
): Promise<PersonDTO> {
  const person = await db.person.update({
    where: { id },
    data,
    include: personInclude,
  });
  return toPersonDTO(person);
}

/** Records that they were actually seen. Separate from the general PATCH
 *  because it is the write the person screen makes most often, and because a
 *  replayed "saw them on Tuesday" must not be able to move the date backwards
 *  past a later sighting already recorded. */
export async function markSeen(
  id: string,
  when: Date,
): Promise<PersonDTO> {
  const existing = await db.person.findUniqueOrThrow({
    where: { id },
    select: { lastSeenAt: true },
  });
  const keep = existing.lastSeenAt !== null && existing.lastSeenAt > when;
  return updatePersonRow(id, keep ? {} : { lastSeenAt: when });
}

// ----------------------------------------------------------------- places

/** Exactly one primary place. A second one marked primary demotes the first,
 *  rather than leaving the row with two answers to "where are they". */
export async function demoteOtherPrimaries(
  tx: DbTransaction,
  personId: string,
  keepId: string,
): Promise<void> {
  await tx.personPlace.updateMany({
    where: { personId, isPrimary: true, id: { not: keepId } },
    data: { isPrimary: false },
  });
}

// ---------------------------------------------------------------- deletion

export type PersonDeletion =
  | { kind: "gone" }
  | { kind: "archived"; person: PersonDTO };

/**
 * Removes someone, as far as it is safe to.
 *
 * Anyone who has been on a bill is archived rather than deleted: their shares
 * are what produced everyone else's balances, and a name that stops resolving
 * turns old bills into arithmetic nobody can check. Someone added by mistake,
 * with nothing attached, goes properly — as a tombstone, so a phone that has
 * been offline is told they are gone rather than syncing them back.
 *
 * Shared by the People and Money contracts so the two can never disagree about
 * what "remove" means.
 */
export async function deletePerson(
  userId: string,
  id: string,
): Promise<PersonDeletion> {
  const person = await db.person.findFirst({ where: { id, userId } });
  // Already gone: a delete replayed from a phone's queue must not fail on its
  // second attempt.
  if (!person) return { kind: "gone" };

  const [shares, paid, settlements] = await Promise.all([
    db.expenseShare.count({
      where: { personId: id, expense: { deletedAt: null } },
    }),
    db.expense.count({ where: { paidByPersonId: id } }),
    db.settlement.count({ where: { personId: id } }),
  ]);

  if (shares + paid + settlements === 0) {
    await db.$transaction([
      // Pure join rows with no history worth keeping, and the one reference a
      // deleted person can still leave dangling.
      db.groupMember.deleteMany({ where: { personId: id } }),
      db.person.update({ where: { id }, data: { deletedAt: new Date() } }),
    ]);
    return { kind: "gone" };
  }

  return {
    kind: "archived",
    person: await updatePersonRow(id, { archivedAt: new Date() }),
  };
}

// ---------------------------------------------------------------- creation

export interface CreatePersonInput extends PersonProfilePatch {
  id?: string;
  name: string;
  color?: string;
  emoji?: string | null;
  defaultPercent?: number | null;
}

/**
 * Adds someone, converging rather than colliding.
 *
 * Three ways this is not a plain insert, all of them about a phone's queue:
 *
 *  - The phone names the row, so a create replayed after a lost response finds
 *    its own row and answers with it instead of writing a second one.
 *  - A person is identified by their name, so adding one this account already
 *    has answers with that row. The browser refuses a duplicate name; a phone
 *    must not, because the same "Mira" added offline on two devices has to
 *    converge on one person rather than stranding a write nothing can replay.
 *  - The name may still be held by someone the user deleted, in which case
 *    bringing them back is both what the user means and the only way past the
 *    unique key.
 *
 * In the converging cases the profile already on the row is left untouched: a
 * create replayed from a queue must never blank out notes written since.
 */
export async function createPerson(
  userId: string,
  input: CreatePersonInput,
): Promise<{ person: PersonDTO; created: boolean }> {
  const claim = await claimMoneyId(userId, input.id, (candidate) =>
    db.person.findUnique({
      where: { id: candidate },
      include: personInclude,
    }),
  );
  if (claim.kind === "replay") {
    return { person: toPersonDTO(claim.row), created: false };
  }

  const existing = await db.person.findFirst({
    where: { userId, name: input.name },
    include: personInclude,
  });
  if (existing) return { person: toPersonDTO(existing), created: false };

  const revived = await reviveDeletedPerson(userId, input.name);
  if (revived) {
    const withProfile = await db.person.findUniqueOrThrow({
      where: { id: revived.id },
      include: personInclude,
    });
    return { person: toPersonDTO(withProfile), created: false };
  }

  // New people go to the end of the arranged order rather than the top: the
  // list the owner built is not reshuffled by an addition.
  const count = await db.person.count({ where: { userId } });
  const person = await db.person.create({
    data: {
      ...(claim.id ? { id: claim.id } : {}),
      userId,
      name: input.name,
      ...(input.color ? { color: input.color } : {}),
      emoji: input.emoji ?? null,
      defaultPercent: input.defaultPercent ?? null,
      order: count,
      ...profileUpdateData(input),
    },
    include: personInclude,
  });
  return { person: toPersonDTO(person), created: true };
}
