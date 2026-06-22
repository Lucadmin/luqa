import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { pullSync } from "@/lib/google/pull-sync";

/**
 * Google Calendar push notification webhook.
 * Google POSTs here when the Luqa calendar changes, with the channel id
 * and resource id in headers. We verify the channel belongs to a user
 * and trigger an incremental pull.
 */
export async function POST(request: Request) {
  const channelId = request.headers.get("x-goog-channel-id");
  const state = request.headers.get("x-goog-resource-state");

  // Ignore the initial "sync" notification sent when the channel is created.
  if (!channelId || state === "sync") {
    return NextResponse.json({ ok: true });
  }

  const conn = await db.googleConnection.findFirst({
    where: { channelId },
    select: { userId: true },
  });

  if (!conn) {
    // Unknown channel — likely an old one after a redeploy.
    return NextResponse.json({ ok: true });
  }

  const origin = new URL(request.url).origin;
  await pullSync(conn.userId, origin).catch((e) =>
    console.error("[webhook] pull-sync failed", e),
  );

  return NextResponse.json({ ok: true });
}
