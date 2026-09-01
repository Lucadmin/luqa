-- Indexes for the habit half of the mobile delta feed.
--
-- `/api/v1/sync` asks each collection for "everything that changed since this
-- cursor", ordered by (updatedAt, id). Habits are read by owner; habit logs
-- have no owner column of their own and are reached through their habit, so
-- each gets the index its side of that query actually walks.

CREATE INDEX "habits_userId_updatedAt_idx" ON "habits"("userId", "updatedAt");

CREATE INDEX "habit_logs_updatedAt_idx" ON "habit_logs"("updatedAt");

CREATE INDEX "habit_logs_habitId_updatedAt_idx" ON "habit_logs"("habitId", "updatedAt");
