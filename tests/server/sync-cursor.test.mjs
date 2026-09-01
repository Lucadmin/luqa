import assert from "node:assert/strict";
import test from "node:test";

import {
  SYNC_COLLECTIONS,
  decodeSyncCursor,
  encodeSyncCursor,
  parseCollections,
  syncLimitFrom,
} from "../../src/lib/sync-cursor.ts";

test("a cursor round-trips the position it was made from", () => {
  const at = new Date("2026-08-31T10:00:00.000Z");
  const decoded = decodeSyncCursor(encodeSyncCursor(at, "expense-1"));

  assert.equal(decoded.t, at.toISOString());
  assert.equal(decoded.id, "expense-1");
});

test("the id is part of the cursor, so a shared timestamp still advances", () => {
  // Rows written in one transaction share a millisecond. A timestamp-only
  // cursor could not get past a full page of them.
  const at = new Date("2026-08-31T10:00:00.000Z");
  const first = encodeSyncCursor(at, "a");
  const second = encodeSyncCursor(at, "b");

  assert.notEqual(first, second);
});

test("an unreadable cursor is treated as no cursor, not as an error", () => {
  // Resyncing from the start is slow but always correct; refusing would leave
  // the device permanently stuck.
  assert.equal(decodeSyncCursor(null), null);
  assert.equal(decodeSyncCursor(""), null);
  assert.equal(decodeSyncCursor("not-base64-at-all!!"), null);
  assert.equal(decodeSyncCursor(Buffer.from("{}").toString("base64url")), null);
  assert.equal(
    decodeSyncCursor(Buffer.from('{"t":"nonsense","id":"x"}').toString("base64url")),
    null,
  );
  assert.equal(
    decodeSyncCursor(Buffer.from('{"t":"2026-08-31T10:00:00.000Z","id":""}').toString("base64url")),
    null,
  );
});

test("limits fall back to the default and are capped", () => {
  assert.equal(syncLimitFrom(null), 200);
  assert.equal(syncLimitFrom("0"), 200);
  assert.equal(syncLimitFrom("-5"), 200);
  assert.equal(syncLimitFrom("nonsense"), 200);
  assert.equal(syncLimitFrom("50"), 50);
  assert.equal(syncLimitFrom("100000"), 500);
});

test("asking for no collections in particular asks for all of them", () => {
  assert.deepEqual(parseCollections(null), [...SYNC_COLLECTIONS]);
  assert.deepEqual(parseCollections(""), [...SYNC_COLLECTIONS]);
  // Nothing recognisable is the same as not narrowing at all, rather than a
  // sync that silently returns nothing.
  assert.deepEqual(parseCollections("nope,also-nope"), [...SYNC_COLLECTIONS]);
});

test("a narrowed sync keeps dependency order, not the order asked for", () => {
  // People have to land before the expenses that point at them.
  assert.deepEqual(parseCollections("expenses,people"), ["people", "expenses"]);
  assert.deepEqual(parseCollections(" people , expenses "), [
    "people",
    "expenses",
  ]);
});

test("habits land before the logs that point at them", () => {
  assert.deepEqual(parseCollections("habitLogs,habits"), [
    "habits",
    "habitLogs",
  ]);
});

test("a habit arrives after the category its progress may be read from", () => {
  // A category-linked TIME habit is meaningless until the category is here.
  const order = parseCollections(null);
  assert.ok(order.indexOf("categories") < order.indexOf("habits"));
  // And its progress is derived from time entries, which must also precede
  // the logs that a day is reconciled against.
  assert.ok(order.indexOf("timeEntries") < order.indexOf("habitLogs"));
});
