/**
 * Google Calendar push-notification channel management.
 *
 * Registers a "watch" channel so Google POSTs to /api/google/webhook
 * whenever the Luqa calendar changes. Channels expire after ~7 days;
 * pullSync renews them automatically each time it runs.
 */

import { google } from "googleapis";
import { db } from "@/lib/db";

const RENEW_BEFORE_MS = 24 * 60 * 60 * 1000; // renew if expiring in <24h

export function needsRenewal(channelExpiry: Date | null): boolean {
  if (!channelExpiry) return true;
  return channelExpiry.getTime() - Date.now() < RENEW_BEFORE_MS;
}

export async function registerWatchChannel(
  userId: string,
  client: InstanceType<typeof google.auth.OAuth2>,
  calendarId: string,
  webhookUrl: string,
): Promise<void> {
  const cal = google.calendar({ version: "v3", auth: client });
  const conn = await db.googleConnection.findUnique({
    where: { userId },
    select: { channelId: true, resourceId: true },
  });

  // Stop the old channel first (best-effort — Google auto-expires them anyway).
  if (conn?.channelId && conn?.resourceId) {
    await cal.channels
      .stop({ requestBody: { id: conn.channelId, resourceId: conn.resourceId } })
      .catch(() => {
        /* ignore — channel may already be expired */
      });
  }

  const res = await cal.events.watch({
    calendarId,
    requestBody: {
      id: crypto.randomUUID(),
      type: "web_hook",
      address: webhookUrl,
    },
  });

  await db.googleConnection.update({
    where: { userId },
    data: {
      channelId: res.data.id ?? null,
      resourceId: res.data.resourceId ?? null,
      channelExpiry: res.data.expiration
        ? new Date(Number(res.data.expiration))
        : null,
    },
  });
}
