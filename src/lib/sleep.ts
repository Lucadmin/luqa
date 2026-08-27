import type { HealthSource, Prisma, SleepEntry } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import type { ImportSleepInput } from "@/lib/validations";
import type { SleepDayStatsDTO, SleepReportDTO, SleepStageDTO } from "@/lib/types";
import { isoDateKey } from "@/lib/time";
import {
  AWAKE_IN_BED_STAGES,
  AWAKE_STAGES,
  DEEP_STAGES,
  LIGHT_STAGES,
  OUT_OF_BED_STAGES,
  REM_STAGES,
  UNKNOWN_STAGES,
  deriveSleepMetrics,
  efficiencyPercent,
  inferSleepMinutes,
  minutesBetween,
  normalizeStageName,
  stageMinutes,
} from "@/lib/health/sleep-metrics";

function jsonValue(value: unknown): Prisma.InputJsonValue | undefined {
  if (value === undefined) return undefined;
  return JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;
}

function generatedExternalId(source: HealthSource, startTime: string, endTime: string): string {
  return `${source.toLowerCase()}:${startTime}:${endTime}`;
}

export async function importSleepEntries(
  userId: string,
  input: ImportSleepInput,
): Promise<{ upserted: number; deleted: number }> {
  const source = input.source as HealthSource;
  const now = new Date();
  let upserted = 0;
  let deleted = 0;

  for (const entry of input.entries) {
    const stages: SleepStageDTO[] = (entry.stages ?? []).map((stage) => ({
      stage: normalizeStageName(stage.stage),
      startTime: new Date(stage.startTime).toISOString(),
      endTime: new Date(stage.endTime).toISOString(),
    }));
    const duration = minutesBetween(entry.startTime, entry.endTime);
    const staged = (names: Set<string>, reported?: number | null) => {
      if (reported !== undefined && reported !== null) return reported;
      const minutes = stageMinutes(stages, names);
      return minutes > 0 ? minutes : null;
    };
    const awakeMinutes = staged(AWAKE_STAGES, entry.awakeMinutes);
    const awakeInBedMinutes = staged(AWAKE_IN_BED_STAGES, entry.awakeInBedMinutes);
    const outOfBedMinutes = staged(OUT_OF_BED_STAGES, entry.outOfBedMinutes);
    const lightMinutes = staged(LIGHT_STAGES, entry.lightMinutes);
    const deepMinutes = staged(DEEP_STAGES, entry.deepMinutes);
    const remMinutes = staged(REM_STAGES, entry.remMinutes);
    const unknownMinutes = staged(UNKNOWN_STAGES, entry.unknownMinutes);
    const sleepMinutes = entry.sleepMinutes ?? inferSleepMinutes(duration, awakeMinutes, stages);
    const derived = deriveSleepMetrics(new Date(entry.startTime), stages);
    const sleepFields = {
      title: entry.title ?? null,
      notes: entry.notes ?? null,
      sourceApp: entry.sourceApp ?? null,
      startTime: new Date(entry.startTime),
      endTime: new Date(entry.endTime),
      startZoneOffset: entry.startZoneOffset ?? null,
      endZoneOffset: entry.endZoneOffset ?? null,
      sleepMinutes,
      awakeMinutes,
      awakeInBedMinutes,
      outOfBedMinutes,
      lightMinutes,
      deepMinutes,
      remMinutes,
      unknownMinutes,
      inBedMinutes: duration,
      efficiencyPercent: efficiencyPercent(sleepMinutes, duration),
      latencyMinutes: derived.latencyMinutes,
      wasoMinutes: derived.wasoMinutes,
      awakeningCount: derived.awakeningCount,
      midpoint: derived.midpoint,
      isNap: entry.isNap ?? false,
      recordingMethod: entry.recordingMethod ?? null,
      deviceModel: entry.deviceModel ?? null,
      stages: jsonValue(stages),
      raw: jsonValue(entry.raw),
    };
    const externalId =
      entry.externalId ?? generatedExternalId(source, entry.startTime, entry.endTime);
    const existing = await db.sleepEntry.findUnique({
      where: {
        userId_source_externalId: {
          userId,
          source,
          externalId,
        },
      },
      select: { id: true, manualOverrideAt: true },
    });

    if (existing?.manualOverrideAt) {
      await db.sleepEntry.update({
        where: { id: existing.id },
        data: {
          sourceApp: entry.sourceApp ?? undefined,
          raw: jsonValue(entry.raw),
          lastSyncedAt: now,
        },
      });
      upserted++;
      continue;
    }

    await db.sleepEntry.upsert({
      where: {
        userId_source_externalId: {
          userId,
          source,
          externalId,
        },
      },
      update: {
        ...sleepFields,
        lastSyncedAt: now,
        deletedAt: null,
        manualOverrideAt: null,
      },
      create: {
        userId,
        source,
        externalId,
        ...sleepFields,
        lastSyncedAt: now,
        manualOverrideAt: null,
      },
    });
    upserted++;
  }

  if (input.deletedExternalIds?.length) {
    const result = await db.sleepEntry.updateMany({
      where: {
        userId,
        source,
        externalId: { in: input.deletedExternalIds },
        manualOverrideAt: null,
        deletedAt: null,
      },
      data: { deletedAt: now, lastSyncedAt: now },
    });
    deleted += result.count;
  }

  return { upserted, deleted };
}

export async function markMissingSleepEntriesDeleted({
  userId,
  source,
  from,
  to,
  externalIds,
}: {
  userId: string;
  source: HealthSource;
  from: Date;
  to: Date;
  externalIds: string[];
}): Promise<number> {
  const result = await db.sleepEntry.updateMany({
    where: {
      userId,
      source,
      endTime: { gte: from, lt: to },
      externalId: { notIn: externalIds },
      deletedAt: null,
      manualOverrideAt: null,
    },
    data: { deletedAt: new Date() },
  });
  return result.count;
}

function asleepMinutesFor(entry: SleepEntry): number {
  if (entry.sleepMinutes !== null) return entry.sleepMinutes;
  const duration = minutesBetween(entry.startTime, entry.endTime);
  return Math.max(0, duration - (entry.awakeMinutes ?? 0));
}

function emptySleepDay(): SleepDayStatsDTO {
  return {
    totalMinutes: 0,
    asleepMinutes: 0,
    awakeMinutes: 0,
    lightMinutes: 0,
    deepMinutes: 0,
    remMinutes: 0,
    sessionCount: 0,
    startTime: null,
    endTime: null,
  };
}

export function buildSleepReport(
  entries: SleepEntry[],
  dayStartHour: number,
): SleepReportDTO {
  const dailySleep: Record<string, SleepDayStatsDTO> = {};

  for (const entry of entries) {
    if (entry.deletedAt) continue;
    const dayKey = isoDateKey(new Date(entry.endTime.getTime() - dayStartHour * 3_600_000));
    const stats = dailySleep[dayKey] ?? emptySleepDay();
    const asleep = asleepMinutesFor(entry);

    stats.totalMinutes += asleep;
    stats.asleepMinutes += asleep;
    stats.awakeMinutes += entry.awakeMinutes ?? 0;
    stats.lightMinutes += entry.lightMinutes ?? 0;
    stats.deepMinutes += entry.deepMinutes ?? 0;
    stats.remMinutes += entry.remMinutes ?? 0;
    stats.sessionCount += 1;

    if (!stats.startTime || entry.startTime < new Date(stats.startTime)) {
      stats.startTime = entry.startTime.toISOString();
    }
    if (!stats.endTime || entry.endTime > new Date(stats.endTime)) {
      stats.endTime = entry.endTime.toISOString();
    }
    dailySleep[dayKey] = stats;
  }

  const dayEntries = Object.entries(dailySleep);
  const totalMinutes = dayEntries.reduce((total, [, day]) => total + day.totalMinutes, 0);
  const best = dayEntries.reduce<{ dayKey: string; minutes: number } | null>(
    (current, [dayKey, day]) =>
      !current || day.totalMinutes > current.minutes
        ? { dayKey, minutes: day.totalMinutes }
        : current,
    null,
  );

  return {
    dailySleep,
    totalMinutes,
    averageMinutes: dayEntries.length > 0 ? totalMinutes / dayEntries.length : 0,
    daysWithSleep: dayEntries.length,
    bestDay: best,
  };
}
