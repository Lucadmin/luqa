import { redirect } from "next/navigation";
import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import {
  GOOGLE_HEALTH_SCOPES,
  makeGoogleHealthOAuthClient,
} from "@/lib/google-health/oauth";

export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const origin = new URL(request.url).origin;
  const client = makeGoogleHealthOAuthClient(`${origin}/api/health/google/callback`);
  const url = client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent",
    scope: GOOGLE_HEALTH_SCOPES,
    state: userId,
  });

  return redirect(url);
}
