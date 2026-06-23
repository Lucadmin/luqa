import { z } from "zod";

export const credentialsSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export const signupSchema = credentialsSchema.extend({
  name: z.string().trim().min(1).max(80).optional(),
});

export type SignupInput = z.infer<typeof signupSchema>;
export type CredentialsInput = z.infer<typeof credentialsSchema>;

// --- Time entries & categories ---

const isoString = z
  .string()
  .refine((s) => !Number.isNaN(Date.parse(s)), "Invalid datetime");

const hexColor = z
  .string()
  .regex(/^#[0-9a-fA-F]{6}$/, "Must be a hex color like #6366f1");

export const createEntrySchema = z
  .object({
    description: z.string().max(500).optional().default(""),
    categoryId: z.string().nullish(),
    startTime: isoString,
    endTime: isoString.nullish(),
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
  })
  .refine(
    (v) =>
      !v.startTime ||
      !v.endTime ||
      Date.parse(v.endTime) > Date.parse(v.startTime),
    { message: "End must be after start", path: ["endTime"] },
  );

export const createCategorySchema = z.object({
  name: z.string().trim().min(1).max(60),
  color: hexColor.optional(),
});

export const updateCategorySchema = z.object({
  name: z.string().trim().min(1).max(60).optional(),
  color: hexColor.optional(),
  archived: z.boolean().optional(),
});

// --- User settings / preferences ---

export const updateSettingsSchema = z.object({
  name: z.string().trim().max(80).nullish(),
  dayStartHour: z.number().int().min(0).max(23).optional(),
  dailyGoalMinutes: z.number().int().min(0).max(1440).optional(),
  weekStartsOn: z.union([z.literal(0), z.literal(1)]).optional(),
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

export type CreateEntryInput = z.infer<typeof createEntrySchema>;
export type UpdateEntryInput = z.infer<typeof updateEntrySchema>;
export type UpdateSettingsInput = z.infer<typeof updateSettingsSchema>;
export type CreateHabitInput = z.infer<typeof createHabitSchema>;
export type UpdateHabitInput = z.infer<typeof updateHabitSchema>;
export type HabitLogInput = z.infer<typeof habitLogSchema>;
