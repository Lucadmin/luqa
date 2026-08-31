import assert from "node:assert/strict";
import test from "node:test";

import {
  createCategorySchema,
  createEntrySchema,
  createGymLocationSchema,
  createGymSessionSchema,
  updateGymSessionSchema,
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

test("a workout carries the id the device minted", () => {
  assert.equal(createGymSessionSchema.parse({ id: ULID }).id, ULID);
  assert.equal(createGymSessionSchema.parse({}).id, undefined);
  assert.equal(createGymSessionSchema.safeParse({ id: "no" }).success, false);
});

test("a gym accepts a preferred id on the same terms", () => {
  assert.equal(
    createGymLocationSchema.parse({ id: ULID, code: "GAR", name: "Garage" }).id,
    ULID,
  );
  assert.equal(
    createGymLocationSchema.safeParse({ id: "no", code: "G", name: "G" })
      .success,
    false,
  );
});

test("an update cannot smuggle in a new id", () => {
  // The id is the row being addressed by the URL; letting a body override it
  // would make PATCH a way to move a workout onto someone else's identity.
  const parsed = updateGymSessionSchema.parse({ id: ULID, notes: "hi" });
  assert.equal("id" in parsed, false);
  assert.equal(parsed.notes, "hi");
});
