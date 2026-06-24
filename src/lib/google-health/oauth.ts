import { google } from "googleapis";
import { db } from "@/lib/db";
import { decryptSecret, encryptSecret } from "@/lib/secret-crypto";

export const GOOGLE_HEALTH_API_BASE = "https://health.googleapis.com/v4";

export const GOOGLE_HEALTH_SCOPES = [
  "https://www.googleapis.com/auth/googlehealth.sleep.readonly",
  "https://www.googleapis.com/auth/userinfo.email",
];

function googleHealthClientId(): string | undefined {
  return process.env.GOOGLE_HEALTH_CLIENT_ID ?? process.env.GOOGLE_CLIENT_ID;
}

function googleHealthClientSecret(): string | undefined {
  return process.env.GOOGLE_HEALTH_CLIENT_SECRET ?? process.env.GOOGLE_CLIENT_SECRET;
}

export function makeGoogleHealthOAuthClient(redirectUri?: string) {
  const uri =
    redirectUri ??
    (process.env.APP_URL
      ? `${process.env.APP_URL}/api/health/google/callback`
      : undefined);
  return new google.auth.OAuth2(
    googleHealthClientId(),
    googleHealthClientSecret(),
    uri,
  );
}

export async function googleHealthClientForUser(userId: string) {
  const conn = await db.googleHealthConnection.findUnique({ where: { userId } });
  if (!conn) return null;

  const client = makeGoogleHealthOAuthClient();
  client.setCredentials({
    access_token: decryptSecret(conn.accessToken),
    refresh_token: decryptSecret(conn.refreshToken),
    expiry_date: conn.expiresAt.getTime(),
  });

  if (conn.expiresAt.getTime() < Date.now() + 60_000) {
    const { credentials } = await client.refreshAccessToken();
    client.setCredentials(credentials);
    await db.googleHealthConnection.update({
      where: { userId },
      data: {
        accessToken: credentials.access_token
          ? encryptSecret(credentials.access_token)
          : conn.accessToken,
        expiresAt: credentials.expiry_date
          ? new Date(credentials.expiry_date)
          : conn.expiresAt,
      },
    });
  }

  const token = await client.getAccessToken();
  return {
    client,
    conn,
    accessToken: token.token ?? conn.accessToken,
  };
}

export async function googleHealthFetch<T>(
  accessToken: string,
  path: string,
  init?: RequestInit,
): Promise<T> {
  const res = await fetch(`${GOOGLE_HEALTH_API_BASE}${path}`, {
    ...init,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      ...(init?.headers ?? {}),
    },
  });

  if (!res.ok) {
    const body = await res.text().catch(() => "");
    throw new Error(`Google Health API request failed (${res.status}): ${body}`);
  }

  return res.json() as Promise<T>;
}
