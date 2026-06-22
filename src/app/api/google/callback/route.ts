import { NextResponse } from "next/server";
import { google } from "googleapis";
import { db } from "@/lib/db";
import { makeOAuthClient } from "@/lib/google/oauth";
import { pullSync } from "@/lib/google/pull-sync";

export async function GET(request: Request) {
  const { searchParams } = new URL(request.url);
  const code = searchParams.get("code");
  const userId = searchParams.get("state"); // we set state=userId in /connect
  const error = searchParams.get("error");

  if (error || !code || !userId) {
    return NextResponse.redirect(
      new URL("/settings?google=denied", process.env.APP_URL ?? ""),
    );
  }

  try {
    const client = makeOAuthClient();
    const { tokens } = await client.getToken(code);

    if (!tokens.refresh_token || !tokens.access_token) {
      return NextResponse.redirect(
        new URL("/settings?google=error", process.env.APP_URL ?? ""),
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
    await pullSync(userId).catch((e) =>
      console.error("[google-callback] initial pull failed", e),
    );

    return NextResponse.redirect(
      new URL("/settings?google=connected", process.env.APP_URL ?? ""),
    );
  } catch (err) {
    console.error("[google-callback] error", err);
    return NextResponse.redirect(
      new URL("/settings?google=error", process.env.APP_URL ?? ""),
    );
  }
}
