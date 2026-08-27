import type { User } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import type { CreateMobileSessionInput } from "@/lib/mobile-api-validation";
import {
  bearerToken,
  createMobileTokenPair,
  hashMobileToken,
  isMobileAccessToken,
  isMobileRefreshToken,
  type MobileTokenPair,
} from "@/lib/mobile-auth-tokens";
import { verifyPassword } from "@/lib/password";
import { isAllowedEmail, normalizeEmail } from "@/lib/security-config";

export type MobileAuthErrorCode =
  | "invalid_credentials"
  | "invalid_token"
  | "expired_token";

export class MobileAuthError extends Error {
  constructor(
    readonly code: MobileAuthErrorCode,
    message: string,
  ) {
    super(message);
    this.name = "MobileAuthError";
  }
}

export interface MobileUser {
  id: string;
  email: string;
  name: string | null;
}

export interface MobileSessionCredentials {
  user: MobileUser;
  accessToken: string;
  accessExpiresAt: string;
  refreshToken: string;
  refreshExpiresAt: string;
}

export interface AuthenticatedMobileSession {
  id: string;
  userId: string;
  user: MobileUser;
}

// Keeps rejected login paths on the same bcrypt cost as a valid account. The
// value is a bcrypt hash of a fixed non-secret placeholder, never a credential.
const DUMMY_PASSWORD_HASH =
  "$2b$12$wUqjiMHPWpEk3z7l0Y9AQ.A1VMztAYjQVs4QYcNI/DHDtsPp4GI9S";

function toMobileUser(user: Pick<User, "id" | "email" | "name">): MobileUser {
  return { id: user.id, email: user.email, name: user.name };
}

function credentialsResponse(
  user: Pick<User, "id" | "email" | "name">,
  tokens: MobileTokenPair,
): MobileSessionCredentials {
  return {
    user: toMobileUser(user),
    accessToken: tokens.accessToken,
    accessExpiresAt: tokens.accessExpiresAt.toISOString(),
    refreshToken: tokens.refreshToken,
    refreshExpiresAt: tokens.refreshExpiresAt.toISOString(),
  };
}

function invalidCredentials(): never {
  throw new MobileAuthError(
    "invalid_credentials",
    "Invalid email or password",
  );
}

function invalidToken(): never {
  throw new MobileAuthError("invalid_token", "Invalid session token");
}

export async function createMobileSession(
  input: CreateMobileSessionInput,
  now = new Date(),
): Promise<MobileSessionCredentials> {
  const email = normalizeEmail(input.email);
  const user = await db.user.findUnique({ where: { email } });
  const passwordValid = await verifyPassword(
    input.password,
    user?.passwordHash ?? DUMMY_PASSWORD_HASH,
  );
  if (!user || !isAllowedEmail(email) || !passwordValid) {
    invalidCredentials();
  }

  const tokens = createMobileTokenPair(now);
  await db.mobileSession.upsert({
    where: {
      userId_deviceId: { userId: user.id, deviceId: input.deviceId },
    },
    create: {
      userId: user.id,
      deviceId: input.deviceId,
      deviceName: input.deviceName,
      accessTokenHash: tokens.accessTokenHash,
      accessExpiresAt: tokens.accessExpiresAt,
      refreshTokenHash: tokens.refreshTokenHash,
      refreshExpiresAt: tokens.refreshExpiresAt,
      lastUsedAt: now,
    },
    update: {
      deviceName: input.deviceName,
      accessTokenHash: tokens.accessTokenHash,
      accessExpiresAt: tokens.accessExpiresAt,
      refreshTokenHash: tokens.refreshTokenHash,
      refreshExpiresAt: tokens.refreshExpiresAt,
      lastUsedAt: now,
      revokedAt: null,
    },
  });

  return credentialsResponse(user, tokens);
}

export async function refreshMobileSession(
  refreshToken: string,
  now = new Date(),
): Promise<MobileSessionCredentials> {
  if (!isMobileRefreshToken(refreshToken)) invalidToken();

  const refreshTokenHash = hashMobileToken(refreshToken);
  const existing = await db.mobileSession.findUnique({
    where: { refreshTokenHash },
    include: { user: true },
  });

  if (!existing || existing.revokedAt || !isAllowedEmail(existing.user.email)) {
    invalidToken();
  }
  if (existing.refreshExpiresAt <= now) {
    throw new MobileAuthError("expired_token", "Session has expired");
  }

  const tokens = createMobileTokenPair(now);
  const rotated = await db.mobileSession.updateMany({
    where: {
      id: existing.id,
      refreshTokenHash,
      revokedAt: null,
      refreshExpiresAt: { gt: now },
    },
    data: {
      accessTokenHash: tokens.accessTokenHash,
      accessExpiresAt: tokens.accessExpiresAt,
      refreshTokenHash: tokens.refreshTokenHash,
      refreshExpiresAt: tokens.refreshExpiresAt,
      lastUsedAt: now,
    },
  });
  if (rotated.count !== 1) invalidToken();

  return credentialsResponse(existing.user, tokens);
}

export async function authenticateMobileRequest(
  request: Request,
  now = new Date(),
): Promise<AuthenticatedMobileSession> {
  const token = bearerToken(request.headers.get("authorization"));
  if (!token || !isMobileAccessToken(token)) invalidToken();

  const session = await db.mobileSession.findUnique({
    where: { accessTokenHash: hashMobileToken(token) },
    include: { user: true },
  });
  if (!session || session.revokedAt || !isAllowedEmail(session.user.email)) {
    invalidToken();
  }
  if (session.accessExpiresAt <= now) {
    throw new MobileAuthError("expired_token", "Access token has expired");
  }

  return {
    id: session.id,
    userId: session.userId,
    user: toMobileUser(session.user),
  };
}

export async function revokeMobileSession(sessionId: string): Promise<void> {
  await db.mobileSession.updateMany({
    where: { id: sessionId, revokedAt: null },
    data: { revokedAt: new Date() },
  });
}
