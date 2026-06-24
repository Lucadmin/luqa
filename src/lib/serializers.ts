import type { Category, Habit, SleepEntry, TimeEntry } from "@/generated/prisma/client";
import type { CategoryDTO, HabitDTO, SleepEntryDTO, SleepStageDTO, TimeEntryDTO } from "@/lib/types";

export function toEntryDTO(e: TimeEntry): TimeEntryDTO {
  return {
    id: e.id,
    description: e.description,
    categoryId: e.categoryId,
    startTime: e.startTime.toISOString(),
    endTime: e.endTime ? e.endTime.toISOString() : null,
    source: e.source,
  };
}

export function toCategoryDTO(c: Category): CategoryDTO {
  return {
    id: c.id,
    name: c.name,
    color: c.color,
    archived: c.archived,
  };
}

function toSleepStages(value: unknown): SleepStageDTO[] {
  if (!Array.isArray(value)) return [];
  return value
    .map((stage) => {
      if (typeof stage !== "object" || stage === null) return null;
      const s = stage as Record<string, unknown>;
      if (
        typeof s.stage !== "string" ||
        typeof s.startTime !== "string" ||
        typeof s.endTime !== "string"
      ) {
        return null;
      }
      return {
        stage: s.stage,
        startTime: s.startTime,
        endTime: s.endTime,
      };
    })
    .filter((stage): stage is SleepStageDTO => stage !== null);
}

export function toSleepDTO(e: SleepEntry): SleepEntryDTO {
  return {
    id: e.id,
    source: e.source,
    externalId: e.externalId,
    title: e.title,
    sourceApp: e.sourceApp,
    startTime: e.startTime.toISOString(),
    endTime: e.endTime.toISOString(),
    sleepMinutes: e.sleepMinutes,
    awakeMinutes: e.awakeMinutes,
    lightMinutes: e.lightMinutes,
    deepMinutes: e.deepMinutes,
    remMinutes: e.remMinutes,
    stages: toSleepStages(e.stages),
  };
}

export function toHabitDTO(h: Habit): HabitDTO {
  return {
    id: h.id,
    name: h.name,
    icon: h.icon,
    color: h.color,
    order: h.order,
    goalType: h.goalType,
    goalPeriod: h.goalPeriod,
    targetCount: h.targetCount,
    targetSeconds: h.targetSeconds,
    categoryId: h.categoryId,
    scheduleType: h.scheduleType,
    weekdays: h.weekdays,
    weekInterval: h.weekInterval,
    intervalDays: h.intervalDays,
    timesPerPeriod: h.timesPerPeriod,
    anchorDate: h.anchorDate,
    dates: h.dates,
    excludedDates: h.excludedDates,
    createdAt: h.createdAt.toISOString(),
  };
}
