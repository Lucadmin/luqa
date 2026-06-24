import { secureCompare } from "@/lib/secure-compare";

function configuredToken(name: string): string | null {
  return process.env[name]?.trim() || null;
}

export function verifyOptionalWebhookToken(
  envName: "GOOGLE_WEBHOOK_TOKEN" | "GOOGLE_HEALTH_WEBHOOK_TOKEN",
  provided: string | null | undefined,
): boolean {
  const expected = configuredToken(envName);
  if (!expected) return true;
  if (!provided) return false;

  return secureCompare(provided, expected);
}

export function bearerToken(header: string | null): string | null {
  if (!header) return null;

  const match = header.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() || null;
}
