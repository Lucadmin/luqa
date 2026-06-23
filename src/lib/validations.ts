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

export type CreateEntryInput = z.infer<typeof createEntrySchema>;
export type UpdateEntryInput = z.infer<typeof updateEntrySchema>;
export type UpdateSettingsInput = z.infer<typeof updateSettingsSchema>;
