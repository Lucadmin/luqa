/**
 * Push-sync: propagate Luqa entry changes → Google Calendar.
 * Called from the API routes after a successful DB write.
 * Failures are swallowed (not surfaced to the user) so tracking
 * never breaks because of a calendar glitch.
 */

import { google } from "googleapis";
import {
  ensureLuqaCalendar,
  entryToEventBody,
  oauthClientForUser,
} from "@/lib/google/oauth";
import { db } from "@/lib/db";

async function getContext(userId: string) {
  const result = await oauthClientForUser(userId);
  if (!result) return null;
  const { client, conn } = result;
  const calendarId = await ensureLuqaCalendar(client, userId, conn.calendarId);
  const cal = google.calendar({ version: "v3", auth: client });
  return { cal, calendarId };
}

export async function pushEntryCreate(
  userId: string,
  entryId: string,
  description: string,
  categoryId: string | null,
  startISO: string,
  endISO: string,
): Promise<void> {
  try {
    const ctx = await getContext(userId);
    if (!ctx) return;

    const category = categoryId
      ? await db.category.findFirst({ where: { id: categoryId, userId } })
      : null;

    const event = await ctx.cal.events.insert({
      calendarId: ctx.calendarId,
      requestBody: entryToEventBody(
        description,
        category?.name,
        category?.color,
        startISO,
        endISO,
      ),
    });

    await db.timeEntry.update({
      where: { id: entryId },
      data: {
        googleEventId: event.data.id,
        googleEtag: event.data.etag,
        lastSyncedAt: new Date(),
      },
    });
  } catch (err) {
    console.error("[push-sync] create failed", err);
  }
}

export async function pushEntryUpdate(
  userId: string,
  entryId: string,
  description: string,
  categoryId: string | null,
  startISO: string,
  endISO: string,
): Promise<void> {
  try {
    const entry = await db.timeEntry.findFirst({
      where: { id: entryId, userId },
      select: { googleEventId: true },
    });
    if (!entry?.googleEventId) {
      // Not yet synced — push as a new create.
      await pushEntryCreate(userId, entryId, description, categoryId, startISO, endISO);
      return;
    }

    const ctx = await getContext(userId);
    if (!ctx) return;

    const category = categoryId
      ? await db.category.findFirst({ where: { id: categoryId, userId } })
      : null;

    const event = await ctx.cal.events.update({
      calendarId: ctx.calendarId,
      eventId: entry.googleEventId,
      requestBody: entryToEventBody(
        description,
        category?.name,
        category?.color,
        startISO,
        endISO,
      ),
    });

    await db.timeEntry.update({
      where: { id: entryId },
      data: {
        googleEtag: event.data.etag,
        lastSyncedAt: new Date(),
      },
    });
  } catch (err) {
    console.error("[push-sync] update failed", err);
  }
}

export async function pushEntryDelete(
  userId: string,
  googleEventId: string,
): Promise<void> {
  try {
    const ctx = await getContext(userId);
    if (!ctx) return;
    await ctx.cal.events.delete({
      calendarId: ctx.calendarId,
      eventId: googleEventId,
    });
  } catch (err) {
    console.error("[push-sync] delete failed", err);
  }
}
