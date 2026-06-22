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
