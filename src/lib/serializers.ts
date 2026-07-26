import type {
  Category,
  Exercise,
  Expense,
  ExpenseShare,
  GroupMember,
  GymLocation,
  GymSession,
  GymSet,
  Habit,
  LifePeriod,
  Person,
  PersonGroup,
  SessionExercise,
  Settlement,
  SleepEntry,
  TimeEntry,
  WeekNote,
} from "@/generated/prisma/client";
import type {
  CategoryDTO,
  ExpenseDTO,
  GymLocationDTO,
  GymSessionDTO,
  HabitDTO,
  LifePeriodDTO,
  PersonDTO,
  PersonGroupDTO,
  SessionExerciseDTO,
  SettlementDTO,
  SleepEntryDTO,
  SleepStageDTO,
  TimeEntryDTO,
  WeekNoteDTO,
} from "@/lib/types";
import { toDateKey } from "@/lib/life";

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
    manualOverrideAt: e.manualOverrideAt?.toISOString() ?? null,
  };
}

export function toLifePeriodDTO(p: LifePeriod): LifePeriodDTO {
  return {
    id: p.id,
    name: p.name,
    color: p.color,
    startDate: toDateKey(p.startDate),
    endDate: p.endDate ? toDateKey(p.endDate) : null,
  };
}

export function toWeekNoteDTO(n: WeekNote): WeekNoteDTO {
  return {
    weekIndex: n.weekIndex,
    highlights: n.highlights,
    lessons: n.lessons,
    rating: n.rating,
    milestone: n.milestone,
  };
}

export function toPersonDTO(p: Person): PersonDTO {
  return {
    id: p.id,
    name: p.name,
    color: p.color,
    emoji: p.emoji,
    defaultPercent: p.defaultPercent,
    order: p.order,
    archived: p.archivedAt !== null,
  };
}

export function toGroupDTO(g: PersonGroup & { members: GroupMember[] }): PersonGroupDTO {
  return {
    id: g.id,
    name: g.name,
    color: g.color,
    emoji: g.emoji,
    order: g.order,
    archived: g.archivedAt !== null,
    memberIds: g.members.map((m) => m.personId),
  };
}

export function toExpenseDTO(e: Expense & { shares: ExpenseShare[] }): ExpenseDTO {
  return {
    id: e.id,
    description: e.description,
    amountCents: e.amountCents,
    date: toDateKey(e.date),
    paidByPersonId: e.paidByPersonId,
    groupId: e.groupId,
    splitMode: e.splitMode,
    myShareCents: e.myShareCents,
    notes: e.notes,
    shares: e.shares.map((s) => ({
      personId: s.personId,
      amountCents: s.amountCents,
      percentBp: s.percentBp,
      gifted: s.gifted,
    })),
    createdAt: e.createdAt.toISOString(),
  };
}

export function toSettlementDTO(s: Settlement): SettlementDTO {
  return {
    id: s.id,
    personId: s.personId,
    amountCents: s.amountCents,
    direction: s.direction,
    date: toDateKey(s.date),
    notes: s.notes,
    createdAt: s.createdAt.toISOString(),
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

// --- Gym log ---

export function toGymLocationDTO(l: GymLocation): GymLocationDTO {
  return {
    id: l.id,
    code: l.code,
    name: l.name,
    color: l.color,
    order: l.order,
    archived: l.archivedAt !== null,
  };
}

export type SessionExerciseWithRelations = SessionExercise & {
  exercise: Exercise;
  sets: GymSet[];
};

export function toSessionExerciseDTO(
  e: SessionExerciseWithRelations,
): SessionExerciseDTO {
  return {
    id: e.id,
    exerciseId: e.exerciseId,
    name: e.exercise.name,
    order: e.order,
    raw: e.raw,
    notes: e.notes,
    sets: [...e.sets]
      .sort((a, b) => a.order - b.order)
      .map((s) => ({ weight: s.weight, reps: s.reps, note: s.note })),
  };
}

export function toGymSessionDTO(
  s: GymSession & { exercises: SessionExerciseWithRelations[] },
): GymSessionDTO {
  return {
    id: s.id,
    date: toDateKey(s.date),
    locationId: s.locationId,
    notes: s.notes,
    exercises: [...s.exercises]
      .sort((a, b) => a.order - b.order)
      .map(toSessionExerciseDTO),
    createdAt: s.createdAt.toISOString(),
  };
}
