import { NextResponse } from "next/server";
import { google } from "googleapis";
import { db } from "@/lib/db";
import { makeOAuthClient } from "@/lib/google/oauth";
import { pullSync } from "@/lib/google/pull-sync";

export async function GET(request: Request) {
  const reqUrl = new URL(request.url);
  const { searchParams } = reqUrl;
  const code = searchParams.get("code");
  const userId = searchParams.get("state"); // we set state=userId in /connect
  const error = searchParams.get("error");
  const origin = reqUrl.origin;

  if (error || !code || !userId) {
    return NextResponse.redirect(
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
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
        expiresAt: tokens.expiry_date ? new Date(tokens.expiry_date) : new Date(Date.now() + 3600_000),
        scope: tokens.scope ?? "",
        googleEmail: userInfo.email,
        // Reset sync token so the first pull does a full re-sync.
        syncToken: null,
      },
      create: {
        userId,
        accessToken: tokens.access_token,
        refreshToken: tokens.refresh_token,
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

    return NextResponse.redirect(
      new URL("/settings?google=connected", origin),
    );
  } catch (err) {
    console.error("[google-callback] error", err);
    return NextResponse.redirect(
      new URL("/settings?google=error", origin),
    );
  }
}
