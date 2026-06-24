import { createHmac, randomBytes } from "crypto";
import { secureCompare } from "@/lib/secure-compare";

export type OAuthStateKind = "google-calendar" | "google-health";

export const OAUTH_STATE_MAX_AGE_SECONDS = 10 * 60;

interface OAuthStatePayload {
  exp: number;
  kind: OAuthStateKind;
  nonce: string;
  userId: string;
}

function signingSecret(): string {
  const secret = process.env.AUTH_SECRET?.trim();
  if (!secret) throw new Error("AUTH_SECRET is required for OAuth state signing");
  return secret;
}

function sign(value: string): string {
  return createHmac("sha256", signingSecret()).update(value).digest("base64url");
}

export function oauthStateCookieName(kind: OAuthStateKind): string {
  return `luqa.oauth.${kind}.state`;
}

export function createOAuthState(userId: string, kind: OAuthStateKind): string {
  const payload: OAuthStatePayload = {
    exp: Date.now() + OAUTH_STATE_MAX_AGE_SECONDS * 1000,
    kind,
    nonce: randomBytes(16).toString("base64url"),
    userId,
  };
  const encoded = Buffer.from(JSON.stringify(payload)).toString("base64url");

  return `${encoded}.${sign(encoded)}`;
}

export function verifyOAuthState(
  value: string | null | undefined,
  kind: OAuthStateKind,
): string | null {
  if (!value) return null;

  const [encoded, signature] = value.split(".");
  if (!encoded || !signature || !secureCompare(signature, sign(encoded))) {
    return null;
  }

  let payload: OAuthStatePayload;
  try {
    payload = JSON.parse(Buffer.from(encoded, "base64url").toString("utf8"));
  } catch {
    return null;
  }

  if (
    payload.kind !== kind ||
    typeof payload.userId !== "string" ||
    payload.exp < Date.now()
  ) {
    return null;
  }

  return payload.userId;
}
