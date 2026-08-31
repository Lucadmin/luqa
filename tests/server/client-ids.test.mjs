import assert from "node:assert/strict";
import test from "node:test";

import {
  createCategorySchema,
  createEntrySchema,
} from "../../src/lib/validations.ts";

const START = "2026-08-31T10:00:00.000Z";
const ULID = "01M1BHZRN70GY9SDXA4P5GAJEF";

test("a create carries the id the device minted", () => {
  const parsed = createEntrySchema.parse({ id: ULID, startTime: START });
  assert.equal(parsed.id, ULID);
});

test("a create without an id is still valid, and the server names the row", () => {
  const parsed = createEntrySchema.parse({ startTime: START });
  assert.equal(parsed.id, undefined);
});

test("an id has to be url-safe and long enough to be unguessable", () => {
  for (const id of ["short", "has spaces", "has/slash", "a".repeat(65)]) {
    assert.equal(
      createEntrySchema.safeParse({ id, startTime: START }).success,
      false,
      `expected ${JSON.stringify(id)} to be rejected`,
    );
  }
});

test("categories accept a preferred id on the same terms", () => {
  assert.equal(
    createCategorySchema.parse({ id: ULID, name: "Admin" }).id,
    ULID,
  );
  assert.equal(
    createCategorySchema.safeParse({ id: "nope", name: "Admin" }).success,
    false,
  );
});
