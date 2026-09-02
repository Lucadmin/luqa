-- When a workout stopped, so "is this still going?" is a question the data can
-- answer.
--
-- Until now a session was only a date, and the app decided a workout was over
-- by comparing that date string to today's. Nothing was written when a workout
-- ended, so a session abandoned mid-set and one trained to completion were
-- indistinguishable, and a workout started at 23:50 was cut off at midnight.
--
-- Null means still open. Existing rows are backfilled from `updatedAt`: every
-- one of them predates this column, so the last time it was touched is the
-- closest honest answer to when the training stopped.

ALTER TABLE "gym_sessions" ADD COLUMN "endedAt" TIMESTAMP(3);

UPDATE "gym_sessions" SET "endedAt" = "updatedAt";
