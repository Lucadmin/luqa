import { google } from "googleapis";
import { NextRequest, NextResponse } from "next/server";
import { db } from "@/lib/db";
import { makeOAuthClient } from "@/lib/google/oauth";
import { pullSync } from "@/lib/google/pull-sync";
import {
  oauthStateCookieName,
  verifyOAuthState,
} from "@/lib/oauth-state";
import { secureCompare } from "@/lib/secure-compare";
import { encryptSecret } from "@/lib/secret-crypto";

const stateCookieName = oauthStateCookieName("google-calendar");

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
  const userId = stateMatches ? verifyOAuthState(state, "google-calendar") : null;

  if (error || !code || !userId) {
    return redirectWithClearedState(
      new URL("/settings?google=denied", origin),
    );
  }

  try {
    const client = makeOAuthClient(`${origin}/api/google/callback`);
    const { tokens } = await client.getToken(code);

    if (!tokens.refresh_token || !tokens.access_token) {
      return NextResponse.redirect(
        new URL("/settings?google=error", origin),
      );
    }

    // Fetch the Google account email for display.
    client.setCredentials(tokens);
    const oauth2 = google.oauth2({ version: "v2", auth: client });
    const { data: userInfo } = await oauth2.userinfo.get();

    await db.googleConnection.upsert({
      where: { userId },
      update: {
        accessToken: encryptSecret(tokens.access_token),
        refreshToken: encryptSecret(tokens.refresh_token),
        expiresAt: tokens.expiry_date ? new Date(tokens.expiry_date) : new Date(Date.now() + 3600_000),
        scope: tokens.scope ?? "",
        googleEmail: userInfo.email,
        // Reset sync token so the first pull does a full re-sync.
        syncToken: null,
      },
      create: {
        userId,
        accessToken: encryptSecret(tokens.access_token),
        refreshToken: encryptSecret(tokens.refresh_token),
        expiresAt: tokens.expiry_date ? new Date(tokens.expiry_date) : new Date(Date.now() + 3600_000),
        scope: tokens.scope ?? "",
        googleEmail: userInfo.email,
      },
    });

    // Do an immediate pull to import existing events.
    // Pass origin so the watch channel can be registered right away.
    await pullSync(userId, origin).catch((e) =>
      console.error("[google-callback] initial pull failed", e),
    );

    return redirectWithClearedState(
      new URL("/settings?google=connected", origin),
    );
  } catch (err) {
    console.error("[google-callback] error", err);
    return redirectWithClearedState(
      new URL("/settings?google=error", origin),
    );
  }
}
