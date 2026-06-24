import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { pullSync } from "@/lib/google/pull-sync";
import { verifyOptionalWebhookToken } from "@/lib/webhook-security";

/**
 * Google Calendar push notification webhook.
 * Google POSTs here when the Luqa calendar changes, with the channel id
 * and resource id in headers. We verify the channel belongs to a user
 * and trigger an incremental pull.
 */
export async function POST(request: Request) {
  const channelId = request.headers.get("x-goog-channel-id");
  const resourceId = request.headers.get("x-goog-resource-id");
  const state = request.headers.get("x-goog-resource-state");
  const token = request.headers.get("x-goog-channel-token");

  if (!verifyOptionalWebhookToken("GOOGLE_WEBHOOK_TOKEN", token)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  // Ignore the initial "sync" notification sent when the channel is created.
  if (!channelId || !resourceId || state === "sync") {
    return NextResponse.json({ ok: true });
  }

  const conn = await db.googleConnection.findFirst({
    where: { channelId, resourceId },
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
