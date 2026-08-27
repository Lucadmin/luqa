import type { HealthMetricType, HealthSource } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import type { ImportHealthSamplesInput } from "@/lib/validations";

/**
 * Imports provider measurements. Idempotent by (user, source, metric,
 * externalId), which for Health Connect is the record's metadata id, so the same
 * sample arriving from a full read and from a change feed collapses onto one row.
 *
 * Sleep sessions do not come through here — they carry stage structure and live
 * in `sleep_entries` via `importSleepEntries`.
 */
export async function importHealthSamples(
  userId: string,
  input: ImportHealthSamplesInput,
): Promise<{ upserted: number; deleted: number }> {
  const source = input.source as HealthSource;
  const now = new Date();
  let upserted = 0;
  let deleted = 0;

  for (const sample of input.samples) {
    const metric = sample.metric as HealthMetricType;
    const identity = {
      userId_source_metric_externalId: {
        userId,
        source,
        metric,
        externalId: sample.externalId,
      },
    };
    const fields = {
      startTime: new Date(sample.startTime),
      endTime: new Date(sample.endTime),
      value: sample.value,
      sourceApp: sample.sourceApp ?? null,
      zoneOffset: sample.zoneOffset ?? null,
      raw:
        sample.raw === undefined
          ? undefined
          : JSON.parse(JSON.stringify(sample.raw)),
    };

    // A sample the user has edited by hand keeps its value; the provider only
    // refreshes provenance. Same rule as sleep, so both behave predictably.
    const existing = await db.healthSample.findUnique({
      where: identity,
      select: { id: true, manualOverrideAt: true },
    });
    if (existing?.manualOverrideAt) {
      await db.healthSample.update({
        where: { id: existing.id },
        data: {
          sourceApp: fields.sourceApp ?? undefined,
          raw: fields.raw,
          lastSyncedAt: now,
        },
      });
      upserted++;
      continue;
    }

    await db.healthSample.upsert({
      where: identity,
      update: { ...fields, lastSyncedAt: now, deletedAt: null },
      create: {
        userId,
        source,
        metric,
        externalId: sample.externalId,
        ...fields,
        lastSyncedAt: now,
      },
    });
    upserted++;
  }

  // Deletions arrive per metric, so group them into one statement per metric
  // rather than one round trip per record id.
  const byMetric = new Map<HealthMetricType, string[]>();
  for (const entry of input.deleted ?? []) {
    const metric = entry.metric as HealthMetricType;
    byMetric.set(metric, [...(byMetric.get(metric) ?? []), entry.externalId]);
  }
  for (const [metric, externalIds] of byMetric) {
    const result = await db.healthSample.updateMany({
      where: {
        userId,
        source,
        metric,
        externalId: { in: externalIds },
        manualOverrideAt: null,
        deletedAt: null,
      },
      data: { deletedAt: now, lastSyncedAt: now },
    });
    deleted += result.count;
  }

  return { upserted, deleted };
}

/**
 * Records that a client successfully pushed a domain, so the UI can show "last
 * synced" without the caller knowing which table the data landed in.
 */
export async function recordHealthSync({
  userId,
  source,
  metric,
  deviceId,
  lastEntryAt,
  backfilledFrom,
}: {
  userId: string;
  source: HealthSource;
  metric: HealthMetricType;
  deviceId?: string | null;
  lastEntryAt?: Date | null;
  backfilledFrom?: Date | null;
}): Promise<void> {
  const now = new Date();
  const existing = await db.healthSyncState.findUnique({
    where: { userId_source_metric: { userId, source, metric } },
    select: { lastEntryAt: true, backfilledFrom: true },
  });

  // Both watermarks only ever move outward, so an incremental push that carries
  // a narrow window cannot shrink what a full backfill already established.
  const nextEntryAt =
    lastEntryAt && (!existing?.lastEntryAt || lastEntryAt > existing.lastEntryAt)
      ? lastEntryAt
      : existing?.lastEntryAt ?? null;
  const nextBackfill =
    backfilledFrom &&
    (!existing?.backfilledFrom || backfilledFrom < existing.backfilledFrom)
      ? backfilledFrom
      : existing?.backfilledFrom ?? null;

  await db.healthSyncState.upsert({
    where: { userId_source_metric: { userId, source, metric } },
    update: {
      lastSyncedAt: now,
      lastEntryAt: nextEntryAt,
      backfilledFrom: nextBackfill,
      lastDeviceId: deviceId ?? undefined,
    },
    create: {
      userId,
      source,
      metric,
      lastSyncedAt: now,
      lastEntryAt: nextEntryAt,
      backfilledFrom: nextBackfill,
      lastDeviceId: deviceId ?? null,
    },
  });
}

export async function listHealthSyncStates(userId: string) {
  const states = await db.healthSyncState.findMany({
    where: { userId },
    orderBy: [{ source: "asc" }, { metric: "asc" }],
  });
  return states.map((state) => ({
    source: state.source,
    metric: state.metric,
    lastSyncedAt: state.lastSyncedAt?.toISOString() ?? null,
    lastEntryAt: state.lastEntryAt?.toISOString() ?? null,
    backfilledFrom: state.backfilledFrom?.toISOString() ?? null,
  }));
}
