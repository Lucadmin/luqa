-- Remember where a merged exercise went. This keeps stale offline workout
-- writes and an old spelling pointed at the canonical exercise instead of
-- recreating the split after the user already fixed it.
ALTER TABLE "exercises" ADD COLUMN "mergedIntoId" TEXT;

CREATE INDEX "exercises_mergedIntoId_idx" ON "exercises"("mergedIntoId");

ALTER TABLE "exercises"
ADD CONSTRAINT "exercises_mergedIntoId_fkey"
FOREIGN KEY ("mergedIntoId") REFERENCES "exercises"("id")
ON DELETE SET NULL ON UPDATE CASCADE;
