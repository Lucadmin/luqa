import { createHash, randomBytes } from "node:crypto";

export const MOBILE_ACCESS_TOKEN_TTL_MS = 15 * 60 * 1000;
export const MOBILE_REFRESH_TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

const ACCESS_PREFIX = "luqa_at_1";
const REFRESH_PREFIX = "luqa_rt_1";
const TOKEN_SECRET_BYTES = 32;

export interface MobileTokenPair {
  accessToken: string;
  accessTokenHash: string;
  accessExpiresAt: Date;
  refreshToken: string;
  refreshTokenHash: string;
  refreshExpiresAt: Date;
}

function randomToken(prefix: string): string {
  return `${prefix}.${randomBytes(TOKEN_SECRET_BYTES).toString("base64url")}`;
}

export function hashMobileToken(token: string): string {
  return createHash("sha256").update(token, "utf8").digest("hex");
}

export function isMobileAccessToken(token: string): boolean {
  return token.startsWith(`${ACCESS_PREFIX}.`) && token.length > ACCESS_PREFIX.length + 20;
}

export function isMobileRefreshToken(token: string): boolean {
  return token.startsWith(`${REFRESH_PREFIX}.`) && token.length > REFRESH_PREFIX.length + 20;
}

export function bearerToken(authorization: string | null): string | null {
  if (!authorization) return null;
  const match = /^Bearer ([^\s]+)$/.exec(authorization);
  return match?.[1] ?? null;
}

export function createMobileTokenPair(now = new Date()): MobileTokenPair {
  const accessToken = randomToken(ACCESS_PREFIX);
  const refreshToken = randomToken(REFRESH_PREFIX);
  return {
    accessToken,
    accessTokenHash: hashMobileToken(accessToken),
    accessExpiresAt: new Date(now.getTime() + MOBILE_ACCESS_TOKEN_TTL_MS),
    refreshToken,
    refreshTokenHash: hashMobileToken(refreshToken),
    refreshExpiresAt: new Date(now.getTime() + MOBILE_REFRESH_TOKEN_TTL_MS),
  };
}
