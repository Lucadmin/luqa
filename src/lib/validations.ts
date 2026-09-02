import { z } from "zod";

export const credentialsSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export const signupSchema = credentialsSchema.extend({
  inviteToken: z.string().trim().max(256).optional(),
  name: z.string().trim().min(1).max(80).optional(),
});

export type SignupInput = z.infer<typeof signupSchema>;
export type CredentialsInput = z.infer<typeof credentialsSchema>;

// --- Time entries & categories ---

export const isoString = z
  .string()
  .refine((s) => !Number.isNaN(Date.parse(s)), "Invalid datetime");

const hexColor = z
  .string()
  .regex(/^#[0-9a-fA-F]{6}$/, "Must be a hex color like #6366f1");

// A row's identity, minted by the client that created it. Offline devices need
// to name a block before the server has seen it, so that a later edit, delete,
// or category reference has something stable to point at — and so a retried
// create is recognised as the same row rather than duplicated.
export const clientId = z
  .string()
  .trim()
  .min(8)
  .max(64)
  .regex(/^[A-Za-z0-9_-]+$/, "Must be url-safe");

/// Who was there. Bounded because it is a dinner, not a mailing list, and an
/// unbounded array is a write nothing else on the row can survive.
const entryPersonIds = z.array(z.string()).max(50).optional();

export const createEntrySchema = z
  .object({
    id: clientId.optional(),
    description: z.string().max(500).optional().default(""),
    categoryId: z.string().nullish(),
    startTime: isoString,
    endTime: isoString.nullish(),
    personIds: entryPersonIds,
  })
  .refine(
    (v) => !v.endTime || Date.parse(v.endTime) > Date.parse(v.startTime),
    { message: "End must be after start", path: ["endTime"] },
  );

export const updateEntrySchema = z
  .object({
    description: z.string().max(500).optional(),
    categoryId: z.string().nullable().optional(),
    startTime: isoString.optional(),
    endTime: isoString.nullable().optional(),
    // Absent leaves the tags alone; an empty array clears them.
    personIds: entryPersonIds,
  })
  .refine(
    (v) =>
      !v.startTime ||
      !v.endTime ||
      Date.parse(v.endTime) > Date.parse(v.startTime),
    { message: "End must be after start", path: ["endTime"] },
  );

export const createCategorySchema = z.object({
  // Only a preference: a category matching by name already exists, so the
  // server may answer with that row's id instead.
  id: clientId.optional(),
  name: z.string().trim().min(1).max(60),
  color: hexColor.optional(),
});

export const updateCategorySchema = z.object({
  name: z.string().trim().min(1).max(60).optional(),
  color: hexColor.optional(),
  archived: z.boolean().optional(),
});

// --- Sleep imports ---

const healthSource = z.enum([
  "HEALTH_CONNECT",
  "APPLE_HEALTH",
  "GOOGLE_HEALTH",
  "MANUAL",
]);
const sleepMinutes = z.number().int().min(0).max(48 * 60);
const recordingMethod = z.enum([
  "AUTOMATICALLY_RECORDED",
  "ACTIVELY_RECORDED",
  "MANUAL_ENTRY",
  "UNKNOWN",
]);

const sleepStageSchema = z
  .object({
    stage: z.string().trim().min(1).max(40),
    startTime: isoString,
    endTime: isoString,
  })
  .refine((v) => Date.parse(v.endTime) > Date.parse(v.startTime), {
    message: "Stage end must be after start",
    path: ["endTime"],
  });

// Stage totals and quality metrics are optional: a provider that reports only
// summary numbers still imports, and anything derivable from `stages` is
// recomputed server-side rather than trusted from the client.
export const sleepEntryImportSchema = z
  .object({
    externalId: z.string().trim().min(1).max(300).optional(),
    title: z.string().trim().max(120).nullish(),
    notes: z.string().trim().max(2000).nullish(),
    sourceApp: z.string().trim().max(120).nullish(),
    startTime: isoString,
    endTime: isoString,
    startZoneOffset: z.string().trim().max(40).nullish(),
    endZoneOffset: z.string().trim().max(40).nullish(),
    sleepMinutes: sleepMinutes.nullish(),
    awakeMinutes: sleepMinutes.nullish(),
    awakeInBedMinutes: sleepMinutes.nullish(),
    outOfBedMinutes: sleepMinutes.nullish(),
    lightMinutes: sleepMinutes.nullish(),
    deepMinutes: sleepMinutes.nullish(),
    remMinutes: sleepMinutes.nullish(),
    unknownMinutes: sleepMinutes.nullish(),
    isNap: z.boolean().optional(),
    recordingMethod: recordingMethod.nullish(),
    deviceModel: z.string().trim().max(120).nullish(),
    stages: z.array(sleepStageSchema).max(300).optional(),
    raw: z.unknown().optional(),
  })
  .refine((v) => Date.parse(v.endTime) > Date.parse(v.startTime), {
    message: "End must be after start",
    path: ["endTime"],
  });

export const importSleepSchema = z.object({
  source: healthSource.default("HEALTH_CONNECT"),
  entries: z.array(sleepEntryImportSchema).max(1000).default([]),
  deletedExternalIds: z.array(z.string().trim().min(1).max(300)).max(1000).optional(),
});

// --- Health samples (steps, heart rate, body metrics) ---

export const healthMetricType = z.enum([
  "STEPS",
  "DISTANCE_METERS",
  "ACTIVE_ENERGY_KCAL",
  "TOTAL_ENERGY_KCAL",
  "EXERCISE_MINUTES",
  "HEART_RATE_BPM",
  "RESTING_HEART_RATE_BPM",
  "HEART_RATE_VARIABILITY_MS",
  "RESPIRATORY_RATE_BPM",
  "BLOOD_OXYGEN_PERCENT",
  "BODY_TEMPERATURE_C",
  "WEIGHT_KG",
  "BODY_FAT_PERCENT",
  "VO2_MAX",
]);

export const healthSampleImportSchema = z
  .object({
    externalId: z.string().trim().min(1).max(300),
    metric: healthMetricType,
    startTime: isoString,
    endTime: isoString,
    value: z.number().finite(),
    sourceApp: z.string().trim().max(120).nullish(),
    zoneOffset: z.string().trim().max(40).nullish(),
    raw: z.unknown().optional(),
  })
  .refine((v) => Date.parse(v.endTime) >= Date.parse(v.startTime), {
    message: "End must not be before start",
    path: ["endTime"],
  });

export const importHealthSamplesSchema = z.object({
  source: healthSource.default("HEALTH_CONNECT"),
  samples: z.array(healthSampleImportSchema).max(5000).default([]),
  deleted: z
    .array(
      z.object({
        metric: healthMetricType,
        externalId: z.string().trim().min(1).max(300),
      }),
    )
    .max(5000)
    .optional(),
});

export const updateSleepSchema = z
  .object({
    title: z.string().trim().max(120).nullish(),
    startTime: isoString.optional(),
    endTime: isoString.optional(),
    sleepMinutes: sleepMinutes.nullish(),
    awakeMinutes: sleepMinutes.nullish(),
    lightMinutes: sleepMinutes.nullish(),
    deepMinutes: sleepMinutes.nullish(),
    remMinutes: sleepMinutes.nullish(),
  })
  .refine(
    (v) =>
      !v.startTime ||
      !v.endTime ||
      Date.parse(v.endTime) > Date.parse(v.startTime),
    { message: "End must be after start", path: ["endTime"] },
  );

// --- User settings / preferences ---

const dateKeyValidation = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Expected YYYY-MM-DD");

export const updateSettingsSchema = z.object({
  name: z.string().trim().max(80).nullish(),
  currency: z
    .string()
    .trim()
    .regex(/^[A-Za-z]{3}$/, "Expected a 3-letter currency code")
    .optional(),
  dayStartHour: z.number().int().min(0).max(23).optional(),
  dailyGoalMinutes: z.number().int().min(0).max(1440).optional(),
  weekStartsOn: z.union([z.literal(0), z.literal(1)]).optional(),
  birthDate: dateKeyValidation.nullish(),
  lifeExpectancyYears: z.number().int().min(40).max(150).optional(),
});

// --- Life overview ---

export const createLifePeriodSchema = z
  .object({
    name: z.string().trim().min(1).max(80),
    color: hexColor.optional(),
    startDate: dateKeyValidation,
    endDate: dateKeyValidation.nullish(),
  })
  .refine((v) => !v.endDate || v.endDate >= v.startDate, {
    message: "End must be on or after start",
    path: ["endDate"],
  });

export const updateLifePeriodSchema = z
  .object({
    name: z.string().trim().min(1).max(80).optional(),
    color: hexColor.optional(),
    startDate: dateKeyValidation.optional(),
    endDate: dateKeyValidation.nullable().optional(),
  })
  .refine(
    (v) => !v.startDate || !v.endDate || v.endDate >= v.startDate,
    { message: "End must be on or after start", path: ["endDate"] },
  );

// Upsert one week's review. When every field is empty the row is removed.
export const upsertWeekNoteSchema = z.object({
  weekIndex: z.number().int().min(0).max(150 * 52),
  highlights: z.string().max(4000).optional().default(""),
  lessons: z.string().max(4000).optional().default(""),
  rating: z.number().int().min(1).max(5).nullish(),
  milestone: z.string().trim().max(120).nullish(),
});

// --- Habits ---

const dateKey = z.string().regex(/^\d{4}-\d{2}-\d{2}$/, "Expected YYYY-MM-DD");

const habitGoalType = z.enum(["TASK", "COUNT", "TIME"]);
const habitGoalPeriod = z.enum(["DAY", "WEEK", "MONTH"]);
const habitScheduleType = z.enum([
  "DAILY",
  "WEEKDAYS",
  "INTERVAL",
  "TIMES_PER_WEEK",
  "TIMES_PER_MONTH",
  "TIMES_PER_YEAR",
  "DATES",
]);

export const createHabitSchema = z.object({
  name: z.string().trim().min(1).max(80),
  icon: z.string().trim().max(40).nullish(),
  color: hexColor.optional(),

  goalType: habitGoalType.optional(),
  goalPeriod: habitGoalPeriod.optional(),
  targetCount: z.number().int().min(1).max(1000).optional(),
  targetSeconds: z.number().int().min(0).max(30 * 24 * 3600).optional(), // up to 30 days worth
  categoryId: z.string().nullish(),

  scheduleType: habitScheduleType.optional(),
  weekdays: z.array(z.number().int().min(0).max(6)).max(7).optional(),
  weekInterval: z.number().int().min(1).max(12).optional(),
  intervalDays: z.number().int().min(1).max(365).optional(),
  intervalFromLastDone: z.boolean().optional(),
  timesPerPeriod: z.number().int().min(1).max(366).optional(),
  anchorDate: dateKey.nullish(),
  dates: z.array(dateKey).max(366).optional(),
  excludedDates: z.array(dateKey).max(366).optional(),
});

export const updateHabitSchema = createHabitSchema.partial().extend({
  order: z.number().int().min(0).optional(),
  archived: z.boolean().optional(),
});

// Reorder: an explicit ordering of habit ids.
export const reorderHabitsSchema = z.object({
  ids: z.array(z.string()).min(1).max(200),
});

// --- Habits, from a native client ---
//
// The phone names a habit before the server has seen it, the same way it names
// a time entry, so an edit or a check-in made while offline has something
// stable to point at.
export const createHabitMobileSchema = createHabitSchema.extend({
  id: clientId.optional(),
});

/// A day's progress as the device believes it to be, rather than an action to
/// replay.
///
/// The web client posts "increment" and lets the server work out what that
/// means. A queued write cannot: a drain that retries after a lost response
/// would increment twice. The phone has already resolved the day locally, so
/// it sends the resulting state and the write becomes idempotent — replaying
/// it lands on the same numbers.
export const putHabitLogSchema = z.object({
  count: z.number().int().min(0).max(100000),
  seconds: z.number().int().min(0).max(30 * 24 * 3600),
  runningSince: z.string().datetime().nullish(),
});

// Mutate progress for a habit on a given day.
export const habitLogSchema = z.object({
  date: dateKey,
  action: z.enum([
    "toggle",
    "increment",
    "decrement",
    "start",
    "stop",
    "setCount",
    "addSeconds",
  ]),
  value: z.number().int().optional(),
});

// --- Shared expenses ---

// Cents throughout. The ceiling is a sanity rail, not a real limit.
const cents = z.number().int().min(0).max(1_000_000_00);
const positiveCents = cents.refine((v) => v > 0, "Amount must be more than zero");
const percentBp = z.number().int().min(0).max(10000);

const splitMode = z.enum(["EQUAL", "PERCENT", "AMOUNT"]);
const settlementDirection = z.enum(["TO_ME", "FROM_ME"]);

export const createPersonSchema = z.object({
  name: z.string().trim().min(1).max(60),
  color: hexColor.optional(),
  emoji: z.string().trim().max(8).nullish(),
  // Whole percent; null means "share equally".
  defaultPercent: z.number().int().min(0).max(100).nullish(),
});

/// The profile half of a person, shared by create and update.
///
/// Birthday parts are validated as parts. A month of 13 or a day of 32 is
/// rejected here rather than turning into a date nobody can explain; whether a
/// given day exists in a given month is not checked, because 29 February has
/// to be storable and the next-occurrence rule already decides what it means.
export const personProfileSchema = z.object({
  nickname: z.string().trim().max(60).nullish(),
  photoUrl: z.string().url().max(500).nullish(),
  birthdayYear: z.number().int().min(1900).max(2200).nullish(),
  birthdayMonth: z.number().int().min(1).max(12).nullish(),
  birthdayDay: z.number().int().min(1).max(31).nullish(),
  // Bounded so a typo cannot create a rhythm nobody will ever be overdue on,
  // or one that reports somebody overdue every day.
  cadenceDays: z.number().int().min(1).max(3650).nullish(),
  lastSeenAt: z.string().datetime().nullish(),
});

export const updatePersonSchema = createPersonSchema
  .partial()
  .extend({
    order: z.number().int().min(0).optional(),
    archived: z.boolean().optional(),
  })
  .merge(personProfileSchema);

export const personNoteSchema = z.object({
  id: z.string().optional(),
  body: z.string().trim().min(1).max(4000),
  pinned: z.boolean().optional().default(false),
  happenedOn: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .nullish(),
});

export const updatePersonNoteSchema = z.object({
  body: z.string().trim().min(1).max(4000).optional(),
  pinned: z.boolean().optional(),
  happenedOn: z
    .string()
    .regex(/^\d{4}-\d{2}-\d{2}$/)
    .nullish(),
});

export const personGiftSchema = z.object({
  id: z.string().optional(),
  idea: z.string().trim().min(1).max(200),
  url: z.string().url().max(500).nullish(),
});

export const updatePersonGiftSchema = z.object({
  idea: z.string().trim().min(1).max(200).optional(),
  url: z.string().url().max(500).nullish(),
  // Null puts it back on the list; a date marks it given.
  givenAt: z.string().datetime().nullish(),
});

export const personPlaceSchema = z.object({
  id: z.string().optional(),
  label: z.string().trim().min(1).max(60),
  city: z.string().trim().min(1).max(120),
  region: z.string().trim().max(120).nullish(),
  country: z.string().trim().max(120).nullish(),
  address: z.string().trim().max(300).nullish(),
  isPrimary: z.boolean().optional().default(false),
});

export const markSeenSchema = z.object({
  seenAt: z.string().datetime().optional(),
});

export const createGroupSchema = z.object({
  name: z.string().trim().min(1).max(60),
  color: hexColor.optional(),
  emoji: z.string().trim().max(8).nullish(),
  memberIds: z.array(z.string()).max(50).optional().default([]),
});

export const updateGroupSchema = createGroupSchema.partial().extend({
  order: z.number().int().min(0).optional(),
  archived: z.boolean().optional(),
});

// One other participant on a bill. Which field matters depends on splitMode;
// the server re-runs the split either way, so extra fields are harmless.
const expenseParticipantSchema = z.object({
  personId: z.string().min(1),
  percentBp: percentBp.nullish(),
  amountCents: cents.nullish(),
  gifted: z.boolean().optional(),
});

export const createExpenseSchema = z.object({
  description: z.string().trim().max(200).optional().default(""),
  amountCents: positiveCents,
  date: dateKey.optional(),
  // Null / omitted = the user paid.
  paidByPersonId: z.string().nullish(),
  groupId: z.string().nullish(),
  splitMode: splitMode.optional().default("EQUAL"),
  // EQUAL only: whether the user is one of the equal parts.
  includeMe: z.boolean().optional().default(true),
  participants: z.array(expenseParticipantSchema).max(50).optional().default([]),
  notes: z.string().trim().max(2000).optional().default(""),
});

export const updateExpenseSchema = createExpenseSchema.partial();

export const createSettlementSchema = z.object({
  personId: z.string().min(1),
  amountCents: positiveCents,
  direction: settlementDirection.optional().default("TO_ME"),
  date: dateKey.optional(),
  notes: z.string().trim().max(500).optional().default(""),
});

export const updateSettlementSchema = createSettlementSchema.partial().omit({
  personId: true,
});

export const reorderPeopleSchema = z.object({
  ids: z.array(z.string()).min(1).max(200),
});

export type CreatePersonInput = z.infer<typeof createPersonSchema>;
export type UpdatePersonInput = z.infer<typeof updatePersonSchema>;
export type PersonNoteInput = z.infer<typeof personNoteSchema>;
export type PersonGiftInput = z.infer<typeof personGiftSchema>;
export type PersonPlaceInput = z.infer<typeof personPlaceSchema>;
export type CreateGroupInput = z.infer<typeof createGroupSchema>;
export type UpdateGroupInput = z.infer<typeof updateGroupSchema>;
export type CreateExpenseInput = z.infer<typeof createExpenseSchema>;
export type UpdateExpenseInput = z.infer<typeof updateExpenseSchema>;
export type CreateSettlementInput = z.infer<typeof createSettlementSchema>;
export type UpdateSettlementInput = z.infer<typeof updateSettlementSchema>;

// --- Gym log ---

export const createGymLocationSchema = z.object({
  // Only a preference: a gym with this code may already exist, in which case
  // the response carries that row's id instead.
  id: clientId.optional(),
  code: z.string().trim().min(1).max(12),
  name: z.string().trim().min(1).max(60),
  color: hexColor.optional(),
});

export const updateGymLocationSchema = createGymLocationSchema
  .partial()
  .omit({ id: true })
  .extend({
    order: z.number().int().min(0).optional(),
    archived: z.boolean().optional(),
  });

// One structured set, as entered through the weight/reps inputs.
const gymSetInputSchema = z.object({
  weight: z.number().min(0).max(2000).nullish(),
  reps: z.number().int().min(0).max(1000).nullish(),
  // Per-set marker, e.g. "lf" / "rf" on a unilateral exercise.
  note: z.string().trim().max(10).nullish(),
});

// One exercise inside a session. `exerciseId` picks a known one; `name`
// find-or-creates, which is what typing a new name in the picker does. The
// display line (`raw`) is derived server-side from `sets` — the client only
// ever sends structured numbers.
const sessionExerciseSchema = z
  .object({
    exerciseId: z.string().min(1).optional(),
    name: z.string().trim().min(1).max(80).optional(),
    sets: z.array(gymSetInputSchema).max(50).optional().default([]),
    notes: z.string().trim().max(2000).optional().default(""),
  })
  .refine((v) => Boolean(v.exerciseId || v.name), {
    message: "Needs an exercise id or a name",
    path: ["name"],
  });

export const createGymSessionSchema = z.object({
  // Client-minted, so a workout started with no signal has an identity the
  // phone can navigate to and keep saving into. Supplying it also makes the
  // create idempotent.
  id: clientId.optional(),
  date: dateKey.optional(),
  locationId: z.string().nullish(),
  notes: z.string().trim().max(4000).optional().default(""),
  exercises: z.array(sessionExerciseSchema).max(60).optional().default([]),
  // Null reopens a finished workout. Omitting it leaves the session's open or
  // finished state exactly as it was, which is what every autosave does.
  endedAt: z.string().datetime().nullish(),
});

// Omitting `exercises` leaves the session's exercises alone; sending it
// replaces them wholesale, which is how the editor saves.
export const updateGymSessionSchema = createGymSessionSchema
  .partial()
  .omit({ id: true });

export const updateExerciseSchema = z.object({
  // Renaming onto a name that already exists merges the two, which is the fix
  // for years of "Lat Pulldown" / "Lat Puldown" drift.
  name: z.string().trim().min(1).max(80).optional(),
  notes: z.string().trim().max(2000).optional(),
  archived: z.boolean().optional(),
});

export const mergeExerciseSchema = z.object({
  targetExerciseId: z.string().trim().min(1),
});

export type CreateGymLocationInput = z.infer<typeof createGymLocationSchema>;
export type UpdateGymLocationInput = z.infer<typeof updateGymLocationSchema>;
export type CreateGymSessionInput = z.infer<typeof createGymSessionSchema>;
export type UpdateGymSessionInput = z.infer<typeof updateGymSessionSchema>;
export type UpdateExerciseInput = z.infer<typeof updateExerciseSchema>;
export type MergeExerciseInput = z.infer<typeof mergeExerciseSchema>;

export type CreateEntryInput = z.infer<typeof createEntrySchema>;
export type UpdateEntryInput = z.infer<typeof updateEntrySchema>;
export type CreateCategoryInput = z.infer<typeof createCategorySchema>;
export type ImportSleepInput = z.infer<typeof importSleepSchema>;
export type ImportHealthSamplesInput = z.infer<typeof importHealthSamplesSchema>;
export type HealthMetricTypeInput = z.infer<typeof healthMetricType>;
export type UpdateSleepInput = z.infer<typeof updateSleepSchema>;
export type UpdateSettingsInput = z.infer<typeof updateSettingsSchema>;
export type CreateLifePeriodInput = z.infer<typeof createLifePeriodSchema>;
export type UpdateLifePeriodInput = z.infer<typeof updateLifePeriodSchema>;
export type UpsertWeekNoteInput = z.infer<typeof upsertWeekNoteSchema>;
export type CreateHabitInput = z.infer<typeof createHabitSchema>;
export type UpdateHabitInput = z.infer<typeof updateHabitSchema>;
export type HabitLogInput = z.infer<typeof habitLogSchema>;
export type CreateHabitMobileInput = z.infer<typeof createHabitMobileSchema>;
export type PutHabitLogInput = z.infer<typeof putHabitLogSchema>;
