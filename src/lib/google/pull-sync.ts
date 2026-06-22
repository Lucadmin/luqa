/**
 * Pull-sync: fetch changes from Google Calendar → Luqa.
 * Uses Google's incremental sync (nextSyncToken) so only deltas are fetched
 * after the first full sync. Idempotent — safe to call multiple times.
 */

import { google } from "googleapis";
import {
  categoryFromEvent,
  ensureLuqaCalendar,
  oauthClientForUser,
} from "@/lib/google/oauth";
import { db } from "@/lib/db";

const SNAP_MS = 5 * 60 * 1000; // 5 minutes in milliseconds

function snapToFiveMin(d: Date): Date {
  return new Date(Math.round(d.getTime() / SNAP_MS) * SNAP_MS);
}

/** Find or create a category by name for this user. */
async function upsertCategory(userId: string, name: string): Promise<string> {
  const existing = await db.category.findFirst({
    where: { userId, name: { equals: name, mode: "insensitive" } },
    select: { id: true },
  });
  if (existing) return existing.id;

  // Auto-pick a color from the palette.
  const count = await db.category.count({ where: { userId } });
  const PALETTE = [
    "#6366f1", "#ec4899", "#f59e0b", "#10b981", "#3b82f6",
    "#8b5cf6", "#ef4444", "#14b8a6", "#f97316", "#06b6d4",
  ];
  const cat = await db.category.create({
    data: { userId, name, color: PALETTE[count % PALETTE.length] },
    select: { id: true },
  });
  return cat.id;
}

export async function pullSync(userId: string): Promise<{ added: number; updated: number; deleted: number }> {
  const result = await oauthClientForUser(userId);
  if (!result) return { added: 0, updated: 0, deleted: 0 };

  const { client, conn } = result;
  const calendarId = await ensureLuqaCalendar(client, userId, conn.calendarId);
  const cal = google.calendar({ version: "v3", auth: client });

  let added = 0, updated = 0, deleted = 0;
  let pageToken: string | undefined;
  let newSyncToken: string | undefined;

  // On the first sync (no syncToken), fetch the last 90 days.
  const timeMin = conn.syncToken
    ? undefined
    : new Date(Date.now() - 90 * 24 * 60 * 60 * 1000).toISOString();

  do {
    const res = await cal.events.list({
      calendarId,
      syncToken: conn.syncToken ?? undefined,
      timeMin,
      singleEvents: true,
      maxResults: 250,
      pageToken,
      showDeleted: true,
    });

    for (const event of res.data.items ?? []) {
      if (!event.id) continue;

      // Deleted events from Google side.
      if (event.status === "cancelled") {
        const entry = await db.timeEntry.findFirst({
          where: { userId, googleEventId: event.id, deletedAt: null },
          select: { id: true },
        });
        if (entry) {
          await db.timeEntry.update({
            where: { id: entry.id },
            data: { deletedAt: new Date() },
          });
          deleted++;
        }
        continue;
      }

      // Only process events that have date-time (not all-day) start/end.
      const startDT = event.start?.dateTime;
      const endDT = event.end?.dateTime;
      if (!startDT || !endDT) continue;

      const startTime = snapToFiveMin(new Date(startDT));
      const endTime = snapToFiveMin(new Date(endDT));
      if (endTime <= startTime) continue;

      const description = event.summary ?? "";
      const categoryName = categoryFromEvent(event.description);
      const categoryId = categoryName
        ? await upsertCategory(userId, categoryName)
        : null;

      const existing = await db.timeEntry.findFirst({
        where: { userId, googleEventId: event.id },
        select: { id: true, googleEtag: true, deletedAt: true },
      });

      if (!existing) {
        await db.timeEntry.create({
          data: {
            userId,
            description,
            categoryId,
            startTime,
            endTime,
            source: "GOOGLE",
            googleEventId: event.id,
            googleEtag: event.etag,
            lastSyncedAt: new Date(),
          },
        });
        added++;
      } else if (existing.googleEtag !== event.etag) {
        // Changed on Google side — update.
        await db.timeEntry.update({
          where: { id: existing.id },
          data: {
            description,
            categoryId,
            startTime,
            endTime,
            googleEtag: event.etag,
            lastSyncedAt: new Date(),
            deletedAt: null,
          },
        });
        updated++;
      }
    }

    pageToken = res.data.nextPageToken ?? undefined;
    if (res.data.nextSyncToken) newSyncToken = res.data.nextSyncToken;
  } while (pageToken);

  // Save the new sync token for the next incremental call.
  if (newSyncToken) {
    await db.googleConnection.update({
      where: { userId },
      data: { syncToken: newSyncToken },
    });
  }

  return { added, updated, deleted };
}
