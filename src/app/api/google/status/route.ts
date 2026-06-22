import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";

export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const conn = await db.googleConnection.findUnique({
    where: { userId },
    select: {
      googleEmail: true,
      calendarId: true,
      updatedAt: true,
    },
  });

  if (!conn) return NextResponse.json({ connected: false });

  return NextResponse.json({
    connected: true,
    googleEmail: conn.googleEmail,
    calendarId: conn.calendarId,
    lastSynced: conn.updatedAt.toISOString(),
  });
}
