import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { pullSync } from "@/lib/google/pull-sync";

// POST /api/google/sync — manually trigger a pull from Google Calendar.
export async function POST() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const result = await pullSync(userId);
  return NextResponse.json({ ok: true, ...result });
}
