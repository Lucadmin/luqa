import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import {
  createOAuthState,
  oauthStateCookieName,
  OAUTH_STATE_MAX_AGE_SECONDS,
} from "@/lib/oauth-state";
import {
  GOOGLE_HEALTH_SCOPES,
  makeGoogleHealthOAuthClient,
} from "@/lib/google-health/oauth";

export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const origin = new URL(request.url).origin;
  const client = makeGoogleHealthOAuthClient(`${origin}/api/health/google/callback`);
  const state = createOAuthState(userId, "google-health");
  const url = client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent",
    scope: GOOGLE_HEALTH_SCOPES,
    state,
  });

  const response = NextResponse.redirect(url);
  response.cookies.set({
    name: oauthStateCookieName("google-health"),
    value: state,
    httpOnly: true,
    maxAge: OAUTH_STATE_MAX_AGE_SECONDS,
    path: "/",
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
  });

  return response;
}
