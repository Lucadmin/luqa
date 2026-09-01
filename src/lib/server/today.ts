import { type DbTransaction, db } from "@/lib/db";
import {
  pushEntryCreate,
  pushEntryDelete,
  pushEntryUpdate,
} from "@/lib/google/push-sync";
import { toCategoryDTO, toEntryDTO, toSleepDTO } from "@/lib/serializers";
import { reviveDeletedCategory } from "@/lib/server/tombstones";
import type {
  CreateCategoryInput,
  CreateEntryInput,
  UpdateEntryInput,
} from "@/lib/validations";

const CATEGORY_PALETTE = [
  "#6366f1",
  "#ec4899",
  "#f59e0b",
  "#10b981",
  "#3b82f6",
  "#8b5cf6",
  "#ef4444",
  "#14b8a6",
  "#f97316",
  "#06b6d4",
];

export class InvalidCategoryError extends Error {
  constructor() {
    super("Unknown category");
    this.name = "InvalidCategoryError";
  }
}

export interface EntryWindow {
  from: Date;
  to: Date;
}

export type EntryWindowResult =
  | ({ ok: true } & EntryWindow)
  | { ok: false; message: string };

export function parseEntryWindow(params: URLSearchParams): EntryWindowResult {
  const from = params.get("from");
  const to = params.get("to");
  if (!from || !to) {
    return { ok: false, message: "from and to are required" };
  }

  const fromDate = new Date(from);
  const toDate = new Date(to);
  if (
    Number.isNaN(fromDate.getTime()) ||
    Number.isNaN(toDate.getTime()) ||
    toDate <= fromDate
  ) {
    return { ok: false, message: "Invalid from/to window" };
  }
  return { ok: true, from: fromDate, to: toDate };
}

export async function listCategories(userId: string) {
  const categories = await db.category.findMany({
    where: { userId },
    orderBy: { name: "asc" },
  });
  return categories.map(toCategoryDTO);
}

export async function createCategory(
  userId: string,
  input: CreateCategoryInput,
) {
  const existing = await db.category.findFirst({
    where: {
      userId,
      name: { equals: input.name, mode: "insensitive" },
    },
  });
  if (existing) {
    return { category: toCategoryDTO(existing), created: false };
  }

  // The name may still be held by a category this user deleted.
  const revived = await reviveDeletedCategory(userId, input.name);
  if (revived) return { category: toCategoryDTO(revived), created: false };

  const count = await db.category.count({ where: { userId } });
  const category = await db.category.create({
    data: {
      // A client-minted id is only honoured when it is free; the response is
      // authoritative either way, so a device that loses the race just adopts
      // whichever id came back.
      ...(input.id && !(await idIsTaken("category", input.id))
        ? { id: input.id }
        : {}),
      userId,
      name: input.name,
      color: input.color ?? CATEGORY_PALETTE[count % CATEGORY_PALETTE.length],
    },
  });
  return { category: toCategoryDTO(category), created: true };
}

/// Who was there rides inside the entry, so every read that produces a DTO
/// includes them.
export const entryInclude = { people: { select: { personId: true } } } as const;

export async function listTimeEntries(userId: string, window: EntryWindow) {
  const entries = await db.timeEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      startTime: { lt: window.to },
      OR: [{ endTime: null }, { endTime: { gt: window.from } }],
    },
    orderBy: { startTime: "asc" },
    include: entryInclude,
  });
  return entries.map(toEntryDTO);
}

/**
 * Replaces who was on an entry.
 *
 * Wholesale rather than merged, because the picker hands back the complete
 * set — the same argument as a person's children. Ids that are not this
 * user's are dropped rather than rejected: a phone replaying a write from its
 * queue may name somebody deleted since, and refusing the whole entry over it
 * would lose a block of time to protect a tag.
 */
async function writeEntryPeople(
  tx: DbTransaction,
  userId: string,
  entryId: string,
  personIds: string[] | undefined,
): Promise<void> {
  if (personIds === undefined) return;

  const owned = await tx.person.findMany({
    where: { id: { in: personIds }, userId, deletedAt: null },
    select: { id: true },
  });

  await tx.timeEntryPerson.deleteMany({ where: { timeEntryId: entryId } });
  if (owned.length === 0) return;
  await tx.timeEntryPerson.createMany({
    data: owned.map((person) => ({
      timeEntryId: entryId,
      personId: person.id,
    })),
  });
}

export class EntryIdConflictError extends Error {
  constructor() {
    super("That id belongs to another account");
    this.name = "EntryIdConflictError";
  }
}

/**
 * Create a block or start a timer. When `input.id` is supplied the write is
 * idempotent: a device that never saw the response can send the same request
 * again and gets the row it already made back, rather than a duplicate. The
 * `created` flag tells the caller which of the two happened.
 */
export async function createTimeEntry(
  userId: string,
  input: CreateEntryInput,
) {
  if (input.id) {
    const replay = await findReplayedEntry(userId, input.id);
    if (replay) return { entry: replay, created: false };
  }

  if (input.categoryId) {
    const category = await db.category.findFirst({
      where: { id: input.categoryId, userId },
      select: { id: true },
    });
    if (!category) throw new InvalidCategoryError();
  }

  const start = new Date(input.startTime);
  let entry;
  try {
    entry = await db.$transaction(async (tx) => {
      if (!input.endTime) {
        await tx.timeEntry.updateMany({
          where: { userId, endTime: null, deletedAt: null },
          data: { endTime: start },
        });
      }
      const created = await tx.timeEntry.create({
        data: {
          ...(input.id ? { id: input.id } : {}),
          userId,
          description: input.description ?? "",
          categoryId: input.categoryId ?? null,
          startTime: start,
          endTime: input.endTime ? new Date(input.endTime) : null,
          source: "APP",
        },
      });
      await writeEntryPeople(tx, userId, created.id, input.personIds);
      return tx.timeEntry.findUniqueOrThrow({
        where: { id: created.id },
        include: entryInclude,
      });
    });
  } catch (error) {
    // Two retries of the same create can race each other. The loser sees a
    // unique-key violation on the id it asked for, which is the same "already
    // done" answer as the replay check above.
    if (input.id && isUniqueViolation(error)) {
      const replay = await findReplayedEntry(userId, input.id);
      if (replay) return { entry: replay, created: false };
    }
    throw error;
  }

  if (entry.endTime) {
    await pushEntryCreate(
      userId,
      entry.id,
      entry.description,
      entry.categoryId,
      entry.startTime.toISOString(),
      entry.endTime.toISOString(),
    );
  }
  return { entry: toEntryDTO(entry), created: true };
}

/**
 * The row a repeated create already produced, or null when the id is free.
 * A soft-deleted row still counts: the create did happen, and resurrecting it
 * would undo a deletion the user has already made.
 */
async function findReplayedEntry(userId: string, id: string) {
  const existing = await db.timeEntry.findUnique({
    where: { id },
    include: entryInclude,
  });
  if (!existing) return null;
  if (existing.userId !== userId) throw new EntryIdConflictError();
  return toEntryDTO(existing);
}

async function idIsTaken(model: "category", id: string) {
  if (model === "category") {
    const existing = await db.category.findUnique({
      where: { id },
      select: { id: true },
    });
    return existing !== null;
  }
  return false;
}

function isUniqueViolation(error: unknown) {
  return (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    (error as { code?: unknown }).code === "P2002"
  );
}

export class EntryRangeError extends Error {
  constructor() {
    super("End must be after start");
    this.name = "EntryRangeError";
  }
}

/**
 * Apply a partial edit. Returns null when the entry does not exist or belongs
 * to someone else, so callers can answer 404 without a second lookup.
 */
export async function updateTimeEntry(
  userId: string,
  id: string,
  input: UpdateEntryInput,
) {
  const existing = await db.timeEntry.findFirst({
    where: { id, userId, deletedAt: null },
  });
  if (!existing) return null;

  const { description, categoryId, startTime, endTime } = input;

  if (categoryId) {
    const owns = await db.category.findFirst({
      where: { id: categoryId, userId },
      select: { id: true },
    });
    if (!owns) throw new InvalidCategoryError();
  }

  // One side of the range may be unchanged, so validate the resulting pair
  // rather than the payload alone.
  const nextStart = startTime ? new Date(startTime) : existing.startTime;
  const nextEnd =
    endTime === undefined
      ? existing.endTime
      : endTime === null
        ? null
        : new Date(endTime);
  if (nextEnd && nextEnd <= nextStart) throw new EntryRangeError();

  const updated = await db.$transaction(async (tx) => {
    await tx.timeEntry.update({
      where: { id },
      data: {
        ...(description !== undefined ? { description } : {}),
        ...(categoryId !== undefined ? { categoryId } : {}),
        ...(startTime !== undefined ? { startTime: nextStart } : {}),
        ...(endTime !== undefined ? { endTime: nextEnd } : {}),
      },
    });
    await writeEntryPeople(tx, userId, id, input.personIds);
    return tx.timeEntry.findUniqueOrThrow({
      where: { id },
      include: entryInclude,
    });
  });

  // Push to Google Calendar (swallows its own errors).
  if (updated.endTime) {
    await pushEntryUpdate(
      userId,
      updated.id,
      updated.description,
      updated.categoryId,
      updated.startTime.toISOString(),
      updated.endTime.toISOString(),
    );
  }

  return toEntryDTO(updated);
}

/** Soft-delete an entry. False when it does not exist or is not this user's. */
export async function deleteTimeEntry(userId: string, id: string) {
  const existing = await db.timeEntry.findFirst({
    where: { id, userId, deletedAt: null },
    select: { id: true, googleEventId: true },
  });
  if (!existing) return false;

  await db.timeEntry.update({
    where: { id },
    data: { deletedAt: new Date() },
  });

  // Remove from Google Calendar (swallows its own errors).
  if (existing.googleEventId) {
    await pushEntryDelete(userId, existing.googleEventId);
  }
  return true;
}

/**
 * Sleep sessions that *woke up* inside the window — sleep is attributed to the
 * day it ends in, which is the day the timeline shows it under.
 */
export async function listSleepEntries(userId: string, window: EntryWindow) {
  const entries = await db.sleepEntry.findMany({
    where: {
      userId,
      deletedAt: null,
      endTime: { gte: window.from, lt: window.to },
    },
    orderBy: { endTime: "asc" },
  });
  return entries.map(toSleepDTO);
}
