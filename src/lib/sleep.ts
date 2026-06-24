import type { Prisma, SleepEntry, SleepSource } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import type { ImportSleepInput } from "@/lib/validations";
import type { SleepDayStatsDTO, SleepReportDTO, SleepStageDTO } from "@/lib/types";
import { isoDateKey } from "@/lib/time";

const AWAKE_STAGES = new Set(["AWAKE", "AWAKE_IN_BED", "OUT_OF_BED", "RESTLESS"]);
const LIGHT_STAGES = new Set(["LIGHT"]);
const DEEP_STAGES = new Set(["DEEP"]);
const REM_STAGES = new Set(["REM"]);
const ASLEEP_STAGES = new Set(["ASLEEP", "SLEEPING", "LIGHT", "DEEP", "REM"]);

function minutesBetween(start: Date | string, end: Date | string): number {
  const startMs = typeof start === "string" ? Date.parse(start) : start.getTime();
  const endMs = typeof end === "string" ? Date.parse(end) : end.getTime();
  return Math.max(0, Math.round((endMs - startMs) / 60000));
}

function jsonValue(value: unknown): Prisma.InputJsonValue | undefined {
  if (value === undefined) return undefined;
  return JSON.parse(JSON.stringify(value)) as Prisma.InputJsonValue;
}

function normalizeStageName(stage: string): string {
  return stage.trim().toUpperCase().replace(/\s+/g, "_");
}

function stageMinutes(stages: SleepStageDTO[], names: Set<string>): number {
  return stages.reduce((total, stage) => {
    const name = normalizeStageName(stage.stage);
    if (!names.has(name)) return total;
    return total + minutesBetween(stage.startTime, stage.endTime);
  }, 0);
}

function inferSleepMinutes(
  durationMinutes: number,
  awakeMinutes: number | null,
  stages: SleepStageDTO[],
): number | null {
  const stagedAsleep = stageMinutes(stages, ASLEEP_STAGES);
  if (stagedAsleep > 0) return stagedAsleep;
  if (awakeMinutes !== null) return Math.max(0, durationMinutes - awakeMinutes);
  return null;
}

function generatedExternalId(source: SleepSource, startTime: string, endTime: string): string {
  return `${source.toLowerCase()}:${startTime}:${endTime}`;
}

export async function importSleepEntries(
  userId: string,
  input: ImportSleepInput,
): Promise<{ upserted: number; deleted: number }> {
  const source = input.source as SleepSource;
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
    const inferredAwake = stageMinutes(stages, AWAKE_STAGES);
    const inferredLight = stageMinutes(stages, LIGHT_STAGES);
    const inferredDeep = stageMinutes(stages, DEEP_STAGES);
    const inferredRem = stageMinutes(stages, REM_STAGES);
    const awakeMinutes = entry.awakeMinutes ?? (inferredAwake > 0 ? inferredAwake : null);
    const lightMinutes = entry.lightMinutes ?? (inferredLight > 0 ? inferredLight : null);
    const deepMinutes = entry.deepMinutes ?? (inferredDeep > 0 ? inferredDeep : null);
    const remMinutes = entry.remMinutes ?? (inferredRem > 0 ? inferredRem : null);
    const sleepMinutes = entry.sleepMinutes ?? inferSleepMinutes(duration, awakeMinutes, stages);
    const externalId =
      entry.externalId ?? generatedExternalId(source, entry.startTime, entry.endTime);

    await db.sleepEntry.upsert({
      where: {
        userId_source_externalId: {
          userId,
          source,
          externalId,
        },
      },
      update: {
        title: entry.title ?? null,
        sourceApp: entry.sourceApp ?? null,
        startTime: new Date(entry.startTime),
        endTime: new Date(entry.endTime),
        startZoneOffset: entry.startZoneOffset ?? null,
        endZoneOffset: entry.endZoneOffset ?? null,
        sleepMinutes,
        awakeMinutes,
        lightMinutes,
        deepMinutes,
        remMinutes,
        stages: jsonValue(stages),
        raw: jsonValue(entry.raw),
        lastSyncedAt: now,
        deletedAt: null,
      },
      create: {
        userId,
        source,
        externalId,
        title: entry.title ?? null,
        sourceApp: entry.sourceApp ?? null,
        startTime: new Date(entry.startTime),
        endTime: new Date(entry.endTime),
        startZoneOffset: entry.startZoneOffset ?? null,
        endZoneOffset: entry.endZoneOffset ?? null,
        sleepMinutes,
        awakeMinutes,
        lightMinutes,
        deepMinutes,
        remMinutes,
        stages: jsonValue(stages),
        raw: jsonValue(entry.raw),
        lastSyncedAt: now,
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
  source: SleepSource;
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
