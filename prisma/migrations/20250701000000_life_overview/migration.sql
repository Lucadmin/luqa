-- AlterTable
ALTER TABLE "users" ADD COLUMN     "birthDate" DATE,
ADD COLUMN     "lifeExpectancyYears" INTEGER NOT NULL DEFAULT 90;

-- CreateTable
CREATE TABLE "life_periods" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "color" TEXT NOT NULL DEFAULT '#6366f1',
    "startDate" DATE NOT NULL,
    "endDate" DATE,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "life_periods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "week_notes" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "weekIndex" INTEGER NOT NULL,
    "highlights" TEXT NOT NULL DEFAULT '',
    "lessons" TEXT NOT NULL DEFAULT '',
    "rating" INTEGER,
    "milestone" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "week_notes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "life_periods_userId_idx" ON "life_periods"("userId");

-- CreateIndex
CREATE INDEX "week_notes_userId_idx" ON "week_notes"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "week_notes_userId_weekIndex_key" ON "week_notes"("userId", "weekIndex");

-- AddForeignKey
ALTER TABLE "life_periods" ADD CONSTRAINT "life_periods_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "week_notes" ADD CONSTRAINT "week_notes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
