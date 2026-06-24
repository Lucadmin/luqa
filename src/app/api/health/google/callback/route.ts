import { google } from "googleapis";
import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { makeGoogleHealthOAuthClient } from "@/lib/google-health/oauth";
import { fetchGoogleHealthIdentity, syncGoogleHealthSleep } from "@/lib/google-health/sync";
import {
  oauthStateCookieName,
  verifyOAuthState,
} from "@/lib/oauth-state";
import { secureCompare } from "@/lib/secure-compare";
import { encryptSecret } from "@/lib/secret-crypto";

const stateCookieName = oauthStateCookieName("google-health");

function redirectWithClearedState(url: URL) {
  const response = NextResponse.redirect(url);
  response.cookies.delete(stateCookieName);
  return response;
}

export async function GET(request: NextRequest) {
  const reqUrl = new URL(request.url);
  const { searchParams } = reqUrl;
  const code = searchParams.get("code");
  const state = searchParams.get("state");
  const error = searchParams.get("error");
  const origin = reqUrl.origin;
  const cookieState = request.cookies.get(stateCookieName)?.value;
  const stateMatches =
    Boolean(state && cookieState) && secureCompare(state as string, cookieState as string);
  const userId = stateMatches ? verifyOAuthState(state, "google-health") : null;

  if (error || !code || !userId) {
    return redirectWithClearedState(new URL("/settings?health=denied", origin));
  }

  try {
    const client = makeGoogleHealthOAuthClient(`${origin}/api/health/google/callback`);
    const { tokens } = await client.getToken(code);

    if (!tokens.refresh_token || !tokens.access_token) {
      return NextResponse.redirect(new URL("/settings?health=error", origin));
    }

    client.setCredentials(tokens);
    const oauth2 = google.oauth2({ version: "v2", auth: client });
    const [{ data: userInfo }, identity] = await Promise.all([
      oauth2.userinfo.get(),
      fetchGoogleHealthIdentity(tokens.access_token),
    ]);

    await db.googleHealthConnection.upsert({
      where: { userId },
      update: {
        accessToken: encryptSecret(tokens.access_token),
        refreshToken: encryptSecret(tokens.refresh_token),
        expiresAt: tokens.expiry_date
          ? new Date(tokens.expiry_date)
          : new Date(Date.now() + 3600_000),
        scope: tokens.scope ?? "",
        googleEmail: userInfo.email,
        healthUserId: identity.healthUserId ?? null,
        lastSyncedAt: null,
      },
      create: {
        userId,
        accessToken: encryptSecret(tokens.access_token),
        refreshToken: encryptSecret(tokens.refresh_token),
        expiresAt: tokens.expiry_date
          ? new Date(tokens.expiry_date)
          : new Date(Date.now() + 3600_000),
        scope: tokens.scope ?? "",
        googleEmail: userInfo.email,
        healthUserId: identity.healthUserId ?? null,
      },
    });

    await syncGoogleHealthSleep(userId).catch((e) =>
      console.error("[google-health-callback] initial sleep sync failed", e),
    );

    return redirectWithClearedState(new URL("/settings?health=connected", origin));
  } catch (err) {
    console.error("[google-health-callback] error", err);
    return redirectWithClearedState(new URL("/settings?health=error", origin));
  }
}
