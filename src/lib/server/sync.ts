import { dbWithDeleted } from "@/lib/db";
import {
  type CollectionDelta,
  type Cursor,
  encodeSyncCursor,
  type SyncCollection,
} from "@/lib/sync-cursor";
import {
  toCategoryDTO,
  toEntryDTO,
  toExpenseDTO,
  toGroupDTO,
  toGymLocationDTO,
  toGymSessionDTO,
  toPersonDTO,
  toSettlementDTO,
  toSleepDTO,
} from "@/lib/serializers";

import { personInclude } from "@/lib/server/people";
import { entryInclude } from "@/lib/server/today";

export * from "@/lib/sync-cursor";

/**
 * The delta feed: "everything about me that changed since I last asked".
 *
 * A phone that has been offline for a week should not have to re-download a
 * year of history to find out about four bills. Each collection carries its
 * own cursor — the `updatedAt` of the last row it handed back — so they
 * advance independently and a big one being paged through never holds up a
 * small one.
 *
 * The cursor is a timestamp rather than an opaque page token because rows
 * change after they are written: an expense edited today has to come back to
 * a device whose copy is a month old, and only "ordered by when it last
 * changed" gets that right.
 */

/// Strictly after the cursor, in (changed-at, id) order. Strict rather than
/// inclusive because the id half makes the position exact: there is no row the
/// client has already seen that this could skip.
function changedSince(userId: string, since: Cursor | null) {
  if (!since) return { userId };
  const t = new Date(since.t);
  return {
    userId,
    OR: [
      { updatedAt: { gt: t } },
      { updatedAt: t, id: { gt: since.id } },
    ],
  };
}

function page<T extends { id: string; updatedAt: Date; deletedAt: Date | null }>(
  rows: T[],
  limit: number,
): { kept: T[]; cursor: string | null; hasMore: boolean } {
  const hasMore = rows.length > limit;
  const kept = hasMore ? rows.slice(0, limit) : rows;
  const last = kept.at(-1);
  return {
    kept,
    cursor: last ? encodeSyncCursor(last.updatedAt, last.id) : null,
    hasMore,
  };
}

function split<T extends { id: string; updatedAt: Date; deletedAt: Date | null }, D>(
  rows: T[],
  limit: number,
  toDTO: (row: T) => D,
): CollectionDelta<D> {
  const { kept, cursor, hasMore } = page(rows, limit);
  return {
    rows: kept.filter((row) => !row.deletedAt).map(toDTO),
    deleted: kept.filter((row) => row.deletedAt).map((row) => row.id),
    cursor,
    hasMore,
  };
}

/// Rows that carry no tombstone of their own. Time and sleep entries already
/// had `deletedAt`; nothing else here can vanish without one.
const ORDER = [{ updatedAt: "asc" as const }, { id: "asc" as const }];

export async function collectionDelta(
  userId: string,
  collection: SyncCollection,
  since: Cursor | null,
  limit: number,
): Promise<CollectionDelta<unknown>> {
  const where = changedSince(userId, since);
  const take = limit + 1;
  const query = { where, orderBy: ORDER, take };

  switch (collection) {
    case "categories":
      return split(
        await dbWithDeleted.category.findMany(query),
        limit,
        toCategoryDTO,
      );
    case "people":
      // The profile children ride inside the person row rather than syncing
      // on their own, so the delta has to carry them. Their writes bump the
      // person's `updatedAt` (see `touchPerson`), which is what puts the row
      // in this page at all.
      return split(
        await dbWithDeleted.person.findMany({
          ...query,
          include: personInclude,
        }),
        limit,
        toPersonDTO,
      );
    case "groups":
      return split(
        await dbWithDeleted.personGroup.findMany({
          ...query,
          include: { members: true },
        }),
        limit,
        toGroupDTO,
      );
    case "gymLocations":
      return split(
        await dbWithDeleted.gymLocation.findMany(query),
        limit,
        toGymLocationDTO,
      );
    case "exercises":
      return split(
        await dbWithDeleted.exercise.findMany(query),
        limit,
        (row) => ({
          id: row.id,
          name: row.name,
          notes: row.notes,
          archived: row.archivedAt !== null,
        }),
      );
    case "timeEntries":
      // Who was there rides inside the entry, so the delta has to carry them
      // too — otherwise a second device shows the dinner without the people,
      // and "last seen" is wrong everywhere but the phone it was typed on.
      return split(
        await dbWithDeleted.timeEntry.findMany({
          ...query,
          include: entryInclude,
        }),
        limit,
        toEntryDTO,
      );
    case "sleepEntries":
      return split(
        await dbWithDeleted.sleepEntry.findMany(query),
        limit,
        toSleepDTO,
      );
    case "expenses":
      return split(
        await dbWithDeleted.expense.findMany({
          ...query,
          include: { shares: true },
        }),
        limit,
        toExpenseDTO,
      );
    case "settlements":
      return split(
        await dbWithDeleted.settlement.findMany(query),
        limit,
        toSettlementDTO,
      );
    case "gymSessions":
      return split(
        await dbWithDeleted.gymSession.findMany({
          ...query,
          include: {
            location: true,
            exercises: {
              orderBy: { order: "asc" },
              include: { exercise: true, sets: { orderBy: { order: "asc" } } },
            },
          },
        }),
        limit,
        toGymSessionDTO,
      );
  }
}

/// The account's own settings, which no collection carries but the money
/// screen cannot render without. Cheap enough to send on every sync.
export async function syncSettings(userId: string) {
  const user = await dbWithDeleted.user.findUnique({
    where: { id: userId },
    select: { currency: true },
  });
  return { currency: user?.currency ?? "EUR" };
}

export async function syncDelta(
  userId: string,
  collections: SyncCollection[],
  cursors: Partial<Record<SyncCollection, Cursor | null>>,
  limit: number,
) {
  const entries = await Promise.all(
    collections.map(
      async (name) =>
        [
          name,
          await collectionDelta(userId, name, cursors[name] ?? null, limit),
        ] as const,
    ),
  );
  return Object.fromEntries(entries) as Record<
    SyncCollection,
    CollectionDelta<unknown>
  >;
}
