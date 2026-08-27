import type { HealthMetricType, HealthSource } from "@/generated/prisma/client";
import { importHealthSamples, recordHealthSync } from "@/lib/health/samples";
import { importSleepEntries, markMissingSleepEntriesDeleted } from "@/lib/sleep";
import type { HealthSyncInput } from "@/lib/mobile-api-validation";

export interface HealthSyncResult {
  sleep: { imported: number; deleted: number };
  samples: { imported: number; deleted: number };
}

function latest(times: (string | undefined)[]): Date | null {
  let newest: number | null = null;
  for (const time of times) {
    if (!time) continue;
    const parsed = Date.parse(time);
    if (Number.isFinite(parsed) && (newest === null || parsed > newest)) {
      newest = parsed;
    }
  }
  return newest === null ? null : new Date(newest);
}

/**
 * Applies one push from a device.
 *
 * The client owns the incremental cursor (a Health Connect changes token is
 * device-local and cannot be replayed server-side), so this accepts whatever
 * window the device read and reconciles it. Two deletion paths exist because
 * they answer different questions:
 *
 *  - `deletedExternalIds` — records the change feed reported as deleted.
 *  - `window` — a full re-read of a range, where anything the server holds but
 *    the device no longer sees was deleted while the app was not watching.
 */
export async function applyHealthSync(
  userId: string,
  input: HealthSyncInput,
): Promise<HealthSyncResult> {
  const source = input.source as HealthSource;

  const sleepResult = await importSleepEntries(userId, {
    source: input.source,
    entries: input.sleep?.entries ?? [],
    deletedExternalIds: input.sleep?.deletedExternalIds,
  });

  let sleepDeleted = sleepResult.deleted;
  const window = input.sleep?.window;
  if (window) {
    // Reconcile only what the device actually re-read. Without a window, a
    // partial push would look like "everything else was deleted".
    sleepDeleted += await markMissingSleepEntriesDeleted({
      userId,
      source,
      from: new Date(window.from),
      to: new Date(window.to),
      externalIds: (input.sleep?.entries ?? [])
        .map((entry) => entry.externalId)
        .filter((id): id is string => Boolean(id)),
    });
  }

  const sampleResult = await importHealthSamples(userId, {
    source: input.source,
    samples: input.samples ?? [],
    deleted: input.deletedSamples,
  });

  const touched = new Set<HealthMetricType>();
  if (input.sleep) touched.add("SLEEP");
  for (const sample of input.samples ?? []) {
    touched.add(sample.metric as HealthMetricType);
  }

  for (const metric of touched) {
    const times =
      metric === "SLEEP"
        ? (input.sleep?.entries ?? []).map((entry) => entry.endTime)
        : (input.samples ?? [])
            .filter((sample) => sample.metric === metric)
            .map((sample) => sample.endTime);
    await recordHealthSync({
      userId,
      source,
      metric,
      deviceId: input.deviceId,
      lastEntryAt: latest(times),
      backfilledFrom:
        metric === "SLEEP" && window ? new Date(window.from) : undefined,
    });
  }

  return {
    sleep: { imported: sleepResult.upserted, deleted: sleepDeleted },
    samples: { imported: sampleResult.upserted, deleted: sampleResult.deleted },
  };
}
