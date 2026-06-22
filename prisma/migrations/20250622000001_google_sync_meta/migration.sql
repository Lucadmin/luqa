-- Add lastSyncedAt to google_connections to track when we last pulled from Google.
ALTER TABLE "google_connections" ADD COLUMN "lastSyncedAt" TIMESTAMP(3);
