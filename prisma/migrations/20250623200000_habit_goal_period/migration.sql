-- Add HabitGoalPeriod enum and goalPeriod column to habits.
-- This enables cumulative TIME goals (e.g. "3h of exercise this week").

CREATE TYPE "HabitGoalPeriod" AS ENUM ('DAY', 'WEEK', 'MONTH');

ALTER TABLE "habits"
  ADD COLUMN "goalPeriod" "HabitGoalPeriod" NOT NULL DEFAULT 'DAY';
