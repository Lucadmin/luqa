/**
 * The sync protocol's own vocabulary: what a cursor is, how big a page may be,
 * and which collections exist.
 *
 * Kept apart from the queries so it can be reasoned about — and tested —
 * without a database anywhere near it.
 */

/// Deliberately small. A first sync pages rather than arriving in one piece,
/// which keeps the response predictable on a phone and lets an interrupted
/// sync resume where it stopped rather than starting again.
const DEFAULT_LIMIT = 200;
const MAX_LIMIT = 500;

export function syncLimitFrom(raw: string | null): number {
  const requested = Number(raw);
  if (!Number.isFinite(requested) || requested < 1) return DEFAULT_LIMIT;
  return Math.min(Math.floor(requested), MAX_LIMIT);
}

export interface CollectionDelta<T> {
  /// Rows created or changed since the cursor, oldest change first.
  rows: T[];
  /// Ids of rows that went away. The client deletes its copies.
  deleted: string[];
  /// Where to resume. Null when this collection has never had a row.
  cursor: string | null;
  /// True when the limit was reached and another page is waiting.
  hasMore: boolean;
}

/// Where a collection got to: when the last row changed, and which row it was.
///
/// The id is not decoration. A timestamp alone cannot advance past a page of
/// rows that all share one millisecond — a bulk import, or anything written in
/// a single transaction — and a cursor that cannot advance is a client that
/// asks for the same page for ever.
export interface Cursor {
  t: string;
  id: string;
}

export function encodeSyncCursor(updatedAt: Date, id: string): string {
  return Buffer.from(
    JSON.stringify({ t: updatedAt.toISOString(), id } satisfies Cursor),
  ).toString("base64url");
}

export function decodeSyncCursor(value: string | null): Cursor | null {
  if (!value) return null;
  try {
    const parsed = JSON.parse(
      Buffer.from(value, "base64url").toString("utf8"),
    ) as Partial<Cursor>;
    if (
      typeof parsed.t !== "string" ||
      typeof parsed.id !== "string" ||
      parsed.id.length === 0 ||
      Number.isNaN(Date.parse(parsed.t))
    ) {
      return null;
    }
    return { t: parsed.t, id: parsed.id };
  } catch {
    return null;
  }
}

/// The collections a device can sync, and the order a full sync should walk
/// them in: a row that others point at arrives before the rows pointing at it.
export const SYNC_COLLECTIONS = [
  "categories",
  "people",
  "groups",
  "gymLocations",
  "exercises",
  "timeEntries",
  "sleepEntries",
  "expenses",
  "settlements",
  "gymSessions",
] as const;

export type SyncCollection = (typeof SYNC_COLLECTIONS)[number];

export function parseCollections(raw: string | null): SyncCollection[] {
  if (!raw) return [...SYNC_COLLECTIONS];
  const asked = new Set(raw.split(",").map((value) => value.trim()));
  const chosen = SYNC_COLLECTIONS.filter((name) => asked.has(name));
  return chosen.length > 0 ? chosen : [...SYNC_COLLECTIONS];
}

