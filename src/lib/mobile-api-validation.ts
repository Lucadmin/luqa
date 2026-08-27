import { z } from "zod";
import {
  credentialsSchema,
  healthMetricType,
  healthSampleImportSchema,
  isoString,
  sleepEntryImportSchema,
} from "@/lib/validations";

export const createMobileSessionSchema = credentialsSchema.extend({
  deviceId: z.string().trim().min(8).max(128),
  deviceName: z.string().trim().min(1).max(120).optional(),
});

export const refreshMobileSessionSchema = z.object({
  refreshToken: z.string().trim().min(32).max(256),
});

export type CreateMobileSessionInput = z.infer<
  typeof createMobileSessionSchema
>;

// Native clients read on-device providers, so the source is whatever platform
// store the app talked to. GOOGLE_HEALTH is deliberately absent: that path is a
// server-side pull and a device must not be able to write rows attributed to it.
const deviceHealthSource = z.enum(["HEALTH_CONNECT", "APPLE_HEALTH"]);

const healthSyncWindow = z
  .object({ from: isoString, to: isoString })
  .refine((v) => Date.parse(v.to) > Date.parse(v.from), {
    message: "Window end must be after start",
    path: ["to"],
  });

export const healthSyncSchema = z.object({
  source: deviceHealthSource.default("HEALTH_CONNECT"),
  deviceId: z.string().trim().min(8).max(128).optional(),
  sleep: z
    .object({
      entries: z.array(sleepEntryImportSchema).max(1000).default([]),
      deletedExternalIds: z
        .array(z.string().trim().min(1).max(300))
        .max(1000)
        .optional(),
      // Present only when the device re-read a full range. It authorizes the
      // server to treat anything unseen inside it as deleted.
      window: healthSyncWindow.optional(),
    })
    .optional(),
  samples: z.array(healthSampleImportSchema).max(5000).optional(),
  deletedSamples: z
    .array(
      z.object({
        metric: healthMetricType,
        externalId: z.string().trim().min(1).max(300),
      }),
    )
    .max(5000)
    .optional(),
});

export type HealthSyncInput = z.infer<typeof healthSyncSchema>;
