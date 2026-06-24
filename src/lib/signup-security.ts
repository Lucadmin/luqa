import { configuredSignupToken } from "@/lib/security-config";
import { secureCompare } from "@/lib/secure-compare";

export function verifySignupToken(candidate: string | null | undefined): boolean {
  const expected = configuredSignupToken();
  if (!expected) return process.env.NODE_ENV !== "production";
  if (!candidate) return false;

  return secureCompare(candidate, expected);
}
