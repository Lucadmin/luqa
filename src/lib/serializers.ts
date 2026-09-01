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
  HabitLog,
  LifePeriod,
  Person,
  PersonChannel,
  PersonGiftIdea,
  PersonGroup,
  PersonNote,
  PersonPlace,
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
  HabitLogDTO,
  LifePeriodDTO,
  PersonChannelDTO,
  PersonDTO,
  PersonGiftIdeaDTO,
  PersonGroupDTO,
  PersonNoteDTO,
  PersonPlaceDTO,
  SessionExerciseDTO,
  SettlementDTO,
  SleepEntryDTO,
  SleepStageDTO,
  TimeEntryDTO,
  WeekNoteDTO,
} from "@/lib/types";
import { toDateKey } from "@/lib/life";

/** `TimeEntryWithPeople` rather than `TimeEntry`: who was there is part of the
 *  row on the wire, so a caller that forgets to include them fails to compile
 *  rather than quietly serving a block of time with nobody in it. */
export type TimeEntryWithPeople = TimeEntry & {
  people?: { personId: string }[];
};

export function toEntryDTO(e: TimeEntryWithPeople): TimeEntryDTO {
  return {
    id: e.id,
    description: e.description,
    categoryId: e.categoryId,
    startTime: e.startTime.toISOString(),
    endTime: e.endTime ? e.endTime.toISOString() : null,
    source: e.source,
    personIds: (e.people ?? []).map((row) => row.personId),
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
    notes: e.notes,
    sourceApp: e.sourceApp,
    startTime: e.startTime.toISOString(),
    endTime: e.endTime.toISOString(),
    sleepMinutes: e.sleepMinutes,
    awakeMinutes: e.awakeMinutes,
    awakeInBedMinutes: e.awakeInBedMinutes,
    outOfBedMinutes: e.outOfBedMinutes,
    lightMinutes: e.lightMinutes,
    deepMinutes: e.deepMinutes,
    remMinutes: e.remMinutes,
    unknownMinutes: e.unknownMinutes,
    inBedMinutes: e.inBedMinutes,
    efficiencyPercent: e.efficiencyPercent,
    latencyMinutes: e.latencyMinutes,
    wasoMinutes: e.wasoMinutes,
    awakeningCount: e.awakeningCount,
    midpoint: e.midpoint?.toISOString() ?? null,
    isNap: e.isNap,
    recordingMethod: e.recordingMethod,
    deviceModel: e.deviceModel,
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

/** The person as every client sees them, children included.
 *
 *  `PersonWithProfile` rather than `Person`: the children are part of the row
 *  as far as the wire is concerned, so a caller that forgets to include them
 *  fails to compile rather than quietly serving a profile with no notes. A
 *  balance row that only needs identity passes them as empty. */
export type PersonWithProfile = Person & {
  places?: PersonPlace[];
  channels?: PersonChannel[];
  notes?: PersonNote[];
  gifts?: PersonGiftIdea[];
};

export function toPersonDTO(p: PersonWithProfile): PersonDTO {
  return {
    id: p.id,
    name: p.name,
    color: p.color,
    emoji: p.emoji,
    defaultPercent: p.defaultPercent,
    order: p.order,
    archived: p.archivedAt !== null,

    nickname: p.nickname,
    photoUrl: p.photoUrl,
    birthdayYear: p.birthdayYear,
    birthdayMonth: p.birthdayMonth,
    birthdayDay: p.birthdayDay,
    cadenceDays: p.cadenceDays,
    lastSeenAt: p.lastSeenAt?.toISOString() ?? null,
    googleResourceName: p.googleResourceName,

    places: (p.places ?? []).map(toPersonPlaceDTO),
    channels: (p.channels ?? []).map(toPersonChannelDTO),
    notes: (p.notes ?? []).map(toPersonNoteDTO),
    gifts: (p.gifts ?? []).map(toPersonGiftIdeaDTO),
  };
}

export function toPersonPlaceDTO(place: PersonPlace): PersonPlaceDTO {
  return {
    id: place.id,
    label: place.label,
    city: place.city,
    region: place.region,
    country: place.country,
    address: place.address,
    latitude: place.latitude,
    longitude: place.longitude,
    isPrimary: place.isPrimary,
    source: place.source,
  };
}

export function toPersonChannelDTO(channel: PersonChannel): PersonChannelDTO {
  return {
    id: channel.id,
    kind: channel.kind,
    label: channel.label,
    value: channel.value,
    source: channel.source,
  };
}

export function toPersonNoteDTO(note: PersonNote): PersonNoteDTO {
  return {
    id: note.id,
    body: note.body,
    pinned: note.pinned,
    happenedOn: note.happenedOn,
    createdAt: note.createdAt.toISOString(),
  };
}

export function toPersonGiftIdeaDTO(gift: PersonGiftIdea): PersonGiftIdeaDTO {
  return {
    id: gift.id,
    idea: gift.idea,
    url: gift.url,
    givenAt: gift.givenAt?.toISOString() ?? null,
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
    archived: h.archivedAt !== null,
    createdAt: h.createdAt.toISOString(),
  };
}

export function toHabitLogDTO(l: HabitLog): HabitLogDTO {
  return {
    id: l.id,
    habitId: l.habitId,
    date: l.date,
    count: l.count,
    seconds: l.seconds,
    runningSince: l.runningSince ? l.runningSince.toISOString() : null,
    completedAt: l.completedAt ? l.completedAt.toISOString() : null,
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
