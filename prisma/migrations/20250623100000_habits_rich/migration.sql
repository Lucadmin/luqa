-- CreateEnum
CREATE TYPE "HabitGoalType" AS ENUM ('TASK', 'COUNT', 'TIME');

-- CreateEnum
CREATE TYPE "HabitScheduleType" AS ENUM ('DAILY', 'WEEKDAYS', 'INTERVAL', 'TIMES_PER_WEEK', 'TIMES_PER_MONTH', 'TIMES_PER_YEAR', 'DATES');

-- AlterTable: habits gain icon/color, goal config, category link, and schedule.
ALTER TABLE "habits" ADD COLUMN     "anchorDate" TEXT,
ADD COLUMN     "categoryId" TEXT,
ADD COLUMN     "color" TEXT NOT NULL DEFAULT '#f5c451',
ADD COLUMN     "dates" TEXT[],
ADD COLUMN     "excludedDates" TEXT[],
ADD COLUMN     "goalType" "HabitGoalType" NOT NULL DEFAULT 'TASK',
ADD COLUMN     "icon" TEXT,
ADD COLUMN     "intervalDays" INTEGER NOT NULL DEFAULT 2,
ADD COLUMN     "scheduleType" "HabitScheduleType" NOT NULL DEFAULT 'DAILY',
ADD COLUMN     "targetCount" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "targetSeconds" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "timesPerPeriod" INTEGER NOT NULL DEFAULT 3,
ADD COLUMN     "weekInterval" INTEGER NOT NULL DEFAULT 1,
ADD COLUMN     "weekdays" INTEGER[],
ADD COLUMN     "updatedAt" TIMESTAMP(3);

-- Backfill updatedAt for existing rows, then enforce NOT NULL (matches @updatedAt).
UPDATE "habits" SET "updatedAt" = CURRENT_TIMESTAMP WHERE "updatedAt" IS NULL;
ALTER TABLE "habits" ALTER COLUMN "updatedAt" SET NOT NULL;

-- AlterTable: habit_logs gain progress fields.
ALTER TABLE "habit_logs" ADD COLUMN     "completedAt" TIMESTAMP(3),
ADD COLUMN     "count" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "runningSince" TIMESTAMP(3),
ADD COLUMN     "seconds" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "updatedAt" TIMESTAMP(3);

-- Existing binary logs represent a completed TASK: mark them done, then backfill updatedAt.
UPDATE "habit_logs" SET "count" = 1, "completedAt" = CURRENT_TIMESTAMP;
UPDATE "habit_logs" SET "updatedAt" = CURRENT_TIMESTAMP WHERE "updatedAt" IS NULL;
ALTER TABLE "habit_logs" ALTER COLUMN "updatedAt" SET NOT NULL;

-- CreateIndex
CREATE INDEX "habits_categoryId_idx" ON "habits"("categoryId");

-- AddForeignKey
ALTER TABLE "habits" ADD CONSTRAINT "habits_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "categories"("id") ON DELETE SET NULL ON UPDATE CASCADE;
