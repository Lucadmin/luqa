import { google } from "googleapis";
import { db } from "@/lib/db";
import { decryptSecret, encryptSecret } from "@/lib/secret-crypto";

// Scopes: read/write calendar events + list calendars.
export const GOOGLE_SCOPES = [
  "https://www.googleapis.com/auth/calendar.events",
  "https://www.googleapis.com/auth/calendar",
  "https://www.googleapis.com/auth/userinfo.email",
];

export const CALENDAR_NAME = "Luqa";

// Color index for Luqa events that have no category color mapping.
// Google uses IDs 1-11; "Blueberry" (#3F51B5) is a decent neutral.
const DEFAULT_COLOR_ID = "1";

// Map a hex color string to the closest Google Calendar color ID.
// Google's palette is fixed (11 colors); we do a simple hue-bucket match.
const HEX_TO_COLOR_ID: Record<string, string> = {
  "#6366f1": "1", // Lavender → Blueberry
  "#818cf8": "1",
  "#ec4899": "6", // Flamingo
  "#f59e0b": "5", // Banana
  "#10b981": "2", // Sage
  "#3b82f6": "9", // Blueberry
  "#8b5cf6": "3", // Grape
  "#ef4444": "11", // Tomato
  "#14b8a6": "7", // Peacock
  "#f97316": "6", // Tangerine
  "#06b6d4": "9", // Peacock
};

export function colorIdForHex(hex: string): string {
  return HEX_TO_COLOR_ID[hex.toLowerCase()] ?? DEFAULT_COLOR_ID;
}

export function makeOAuthClient(redirectUri?: string) {
  const uri =
    redirectUri ??
    (process.env.APP_URL ? `${process.env.APP_URL}/api/google/callback` : undefined);
  return new google.auth.OAuth2(
    process.env.GOOGLE_CLIENT_ID,
    process.env.GOOGLE_CLIENT_SECRET,
    uri,
  );
}

/** Build an OAuth2 client pre-loaded with the user's stored tokens.
 *  Automatically refreshes the access token if it has expired. */
export async function oauthClientForUser(userId: string) {
  const conn = await db.googleConnection.findUnique({
    where: { userId },
  });
  if (!conn) return null;

  const client = makeOAuthClient();
  client.setCredentials({
    access_token: decryptSecret(conn.accessToken),
    refresh_token: decryptSecret(conn.refreshToken),
    expiry_date: conn.expiresAt.getTime(),
  });

  // If the access token is expired or close to it, refresh now.
  if (conn.expiresAt.getTime() < Date.now() + 60_000) {
    const { credentials } = await client.refreshAccessToken();
    client.setCredentials(credentials);
    await db.googleConnection.update({
      where: { userId },
      data: {
        accessToken: credentials.access_token
          ? encryptSecret(credentials.access_token)
          : conn.accessToken,
        expiresAt: credentials.expiry_date
          ? new Date(credentials.expiry_date)
          : conn.expiresAt,
      },
    });
  }

  return { client, conn };
}

// ─── Event serialisation ─────────────────────────────────────────────────────

/**
 * Build the event body for a time entry to push to Google Calendar.
 * We encode the category name in the description so we can parse it back
 * on the pull direction.
 */
export function entryToEventBody(
  description: string,
  categoryName: string | null | undefined,
  categoryColor: string | null | undefined,
  startISO: string,
  endISO: string,
) {
  return {
    summary: description || "(no title)",
    description: categoryName
      ? `Category: ${categoryName}\n\nTracked with Luqa`
      : "Tracked with Luqa",
    colorId: categoryColor ? colorIdForHex(categoryColor) : DEFAULT_COLOR_ID,
    start: { dateTime: startISO, timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone },
    end: { dateTime: endISO, timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone },
    extendedProperties: {
      private: {
        luqa: "true",
        ...(categoryName ? { luqaCategory: categoryName } : {}),
      },
    },
  };
}

/** Parse the category name embedded in a Google Calendar event description. */
export function categoryFromEvent(description?: string | null): string | null {
  if (!description) return null;
  const match = description.match(/^Category:\s*(.+)/m);
  return match ? match[1].trim() : null;
}

// ─── Find or create the dedicated Luqa calendar ──────────────────────────────

export async function ensureLuqaCalendar(
  client: InstanceType<typeof google.auth.OAuth2>,
  userId: string,
  existingCalendarId: string | null | undefined,
): Promise<string> {
  const cal = google.calendar({ version: "v3", auth: client });

  // Verify the stored calendar still exists.
  if (existingCalendarId) {
    try {
      await cal.calendars.get({ calendarId: existingCalendarId });
      return existingCalendarId;
    } catch {
      // Deleted externally — fall through and recreate.
    }
  }

  // Search existing calendars for one we created before.
  const list = await cal.calendarList.list();
  const found = list.data.items?.find((c) => c.summary === CALENDAR_NAME);
  if (found?.id) {
    await db.googleConnection.update({
      where: { userId },
      data: { calendarId: found.id },
    });
    return found.id;
  }

  // Create a new calendar.
  const created = await cal.calendars.insert({
    requestBody: { summary: CALENDAR_NAME },
  });
  const newId = created.data.id!;
  await db.googleConnection.update({
    where: { userId },
    data: { calendarId: newId },
  });
  return newId;
}
