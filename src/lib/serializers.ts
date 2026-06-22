import type { Category, TimeEntry } from "@/generated/prisma/client";
import type { CategoryDTO, TimeEntryDTO } from "@/lib/types";

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
