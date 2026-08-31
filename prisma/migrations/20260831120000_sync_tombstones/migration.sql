-- Tombstones, so a phone that has been offline can be told what went away.
--
-- A delta feed answers "everything that changed since this cursor". A row that
-- was hard-deleted cannot appear in that answer, so a device would keep a copy
-- of it for ever. These columns make a deletion something the feed can carry.
--
-- Every ordinary read filters `deletedAt IS NULL`; only the sync endpoints
-- look at deleted rows, and then only to report their ids.

ALTER TABLE "people" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "person_groups" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "expenses" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "settlements" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "categories" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "gym_locations" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "exercises" ADD COLUMN "deletedAt" TIMESTAMP(3);
ALTER TABLE "gym_sessions" ADD COLUMN "deletedAt" TIMESTAMP(3);

-- Every delta query is "this user's rows, ordered by when they last changed".
CREATE INDEX "people_userId_updatedAt_idx" ON "people"("userId", "updatedAt");
CREATE INDEX "person_groups_userId_updatedAt_idx" ON "person_groups"("userId", "updatedAt");
CREATE INDEX "expenses_userId_updatedAt_idx" ON "expenses"("userId", "updatedAt");
CREATE INDEX "settlements_userId_updatedAt_idx" ON "settlements"("userId", "updatedAt");
CREATE INDEX "categories_userId_updatedAt_idx" ON "categories"("userId", "updatedAt");
CREATE INDEX "gym_locations_userId_updatedAt_idx" ON "gym_locations"("userId", "updatedAt");
CREATE INDEX "exercises_userId_updatedAt_idx" ON "exercises"("userId", "updatedAt");
CREATE INDEX "gym_sessions_userId_updatedAt_idx" ON "gym_sessions"("userId", "updatedAt");
