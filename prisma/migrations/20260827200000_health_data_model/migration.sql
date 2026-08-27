-- Generalize the sleep-only source enum into a shared health source.
ALTER TYPE "SleepSource" RENAME TO "HealthSource";
ALTER TYPE "HealthSource" ADD VALUE IF NOT EXISTS 'APPLE_HEALTH' AFTER 'HEALTH_CONNECT';

-- CreateEnum
CREATE TYPE "HealthMetricType" AS ENUM (
    'SLEEP',
    'STEPS',
    'DISTANCE_METERS',
    'ACTIVE_ENERGY_KCAL',
    'TOTAL_ENERGY_KCAL',
    'EXERCISE_MINUTES',
    'HEART_RATE_BPM',
    'RESTING_HEART_RATE_BPM',
    'HEART_RATE_VARIABILITY_MS',
    'RESPIRATORY_RATE_BPM',
    'BLOOD_OXYGEN_PERCENT',
    'BODY_TEMPERATURE_C',
    'WEIGHT_KG',
    'BODY_FAT_PERCENT',
    'VO2_MAX'
);

-- Richer sleep detail. Health Connect reports stages the old columns collapsed
-- away, plus quality metrics now derived once on import.
ALTER TABLE "sleep_entries"
    ADD COLUMN "notes" TEXT,
    ADD COLUMN "awakeInBedMinutes" INTEGER,
    ADD COLUMN "outOfBedMinutes" INTEGER,
    ADD COLUMN "unknownMinutes" INTEGER,
    ADD COLUMN "inBedMinutes" INTEGER,
    ADD COLUMN "efficiencyPercent" DOUBLE PRECISION,
    ADD COLUMN "latencyMinutes" INTEGER,
    ADD COLUMN "wasoMinutes" INTEGER,
    ADD COLUMN "awakeningCount" INTEGER,
    ADD COLUMN "midpoint" TIMESTAMP(3),
    ADD COLUMN "isNap" BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN "recordingMethod" TEXT,
    ADD COLUMN "deviceModel" TEXT;

-- Backfill the one metric derivable without the stage timeline.
UPDATE "sleep_entries"
SET "inBedMinutes" = GREATEST(0, ROUND(EXTRACT(EPOCH FROM ("endTime" - "startTime")) / 60))
WHERE "inBedMinutes" IS NULL;

-- CreateTable
CREATE TABLE "health_samples" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "source" "HealthSource" NOT NULL,
    "metric" "HealthMetricType" NOT NULL,
    "externalId" TEXT NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL,
    "endTime" TIMESTAMP(3) NOT NULL,
    "value" DOUBLE PRECISION NOT NULL,
    "sourceApp" TEXT,
    "zoneOffset" TEXT,
    "raw" JSONB,
    "lastSyncedAt" TIMESTAMP(3),
    "manualOverrideAt" TIMESTAMP(3),
    "deletedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "health_samples_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "health_sync_states" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "source" "HealthSource" NOT NULL,
    "metric" "HealthMetricType" NOT NULL,
    "lastSyncedAt" TIMESTAMP(3),
    "lastEntryAt" TIMESTAMP(3),
    "lastDeviceId" TEXT,
    "backfilledFrom" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "health_sync_states_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "health_samples_userId_source_metric_externalId_key" ON "health_samples"("userId", "source", "metric", "externalId");

-- CreateIndex
CREATE INDEX "health_samples_userId_metric_startTime_idx" ON "health_samples"("userId", "metric", "startTime");

-- CreateIndex
CREATE INDEX "health_samples_userId_metric_endTime_idx" ON "health_samples"("userId", "metric", "endTime");

-- CreateIndex
CREATE UNIQUE INDEX "health_sync_states_userId_source_metric_key" ON "health_sync_states"("userId", "source", "metric");

-- AddForeignKey
ALTER TABLE "health_samples" ADD CONSTRAINT "health_samples_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "health_sync_states" ADD CONSTRAINT "health_sync_states_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
