import { z } from "zod";
import { credentialsSchema } from "@/lib/validations";

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
