-- CreateEnum
CREATE TYPE "SleepSource" AS ENUM ('HEALTH_CONNECT', 'GOOGLE_HEALTH', 'MANUAL');

-- CreateTable
CREATE TABLE "sleep_entries" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "source" "SleepSource" NOT NULL,
    "externalId" TEXT NOT NULL,
    "title" TEXT,
    "sourceApp" TEXT,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "startZoneOffset" TEXT,
    "endZoneOffset" TEXT,
    "sleepMinutes" INTEGER,
    "awakeMinutes" INTEGER,
    "lightMinutes" INTEGER,
    "deepMinutes" INTEGER,
    "remMinutes" INTEGER,
    "stages" JSONB,
    "raw" JSONB,
    "lastSyncedAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "sleep_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "google_health_connections" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "googleEmail" TEXT,
    "healthUserId" TEXT,
    "accessToken" TEXT NOT NULL,
    "refreshToken" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "scope" TEXT NOT NULL,
    "lastSyncedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "google_health_connections_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "sleep_entries_userId_endTime_idx" ON "sleep_entries"("userId", "endTime");

-- CreateIndex
CREATE INDEX "sleep_entries_userId_startTime_idx" ON "sleep_entries"("userId", "startTime");

-- CreateIndex
CREATE UNIQUE INDEX "sleep_entries_userId_source_externalId_key" ON "sleep_entries"("userId", "source", "externalId");

-- CreateIndex
CREATE UNIQUE INDEX "google_health_connections_userId_key" ON "google_health_connections"("userId");

-- AddForeignKey
ALTER TABLE "sleep_entries" ADD CONSTRAINT "sleep_entries_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "google_health_connections" ADD CONSTRAINT "google_health_connections_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
