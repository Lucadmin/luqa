import { redirect } from "next/navigation";
import { GOOGLE_SCOPES, makeOAuthClient } from "@/lib/google/oauth";
import { getUserId } from "@/lib/api-auth";
import { NextResponse } from "next/server";

export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const client = makeOAuthClient();
  const url = client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent", // always return a refresh_token
    scope: GOOGLE_SCOPES,
    state: userId,
  });

  return redirect(url);
}
