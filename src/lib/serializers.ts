import type { Category, Habit, TimeEntry } from "@/generated/prisma/client";
import type { CategoryDTO, HabitDTO, TimeEntryDTO } from "@/lib/types";

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
