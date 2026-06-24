import { GOOGLE_SCOPES, makeOAuthClient } from "@/lib/google/oauth";
import { getUserId } from "@/lib/api-auth";
import { NextResponse } from "next/server";
import {
  createOAuthState,
  oauthStateCookieName,
  OAUTH_STATE_MAX_AGE_SECONDS,
} from "@/lib/oauth-state";

export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const origin = new URL(request.url).origin;
  const client = makeOAuthClient(`${origin}/api/google/callback`);
  const state = createOAuthState(userId, "google-calendar");
  const url = client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent", // always return a refresh_token
    scope: GOOGLE_SCOPES,
    state,
  });

  const response = NextResponse.redirect(url);
  response.cookies.set({
    name: oauthStateCookieName("google-calendar"),
    value: state,
    httpOnly: true,
    maxAge: OAUTH_STATE_MAX_AGE_SECONDS,
    path: "/",
    sameSite: "lax",
    secure: process.env.NODE_ENV === "production",
  });

  return response;
}
