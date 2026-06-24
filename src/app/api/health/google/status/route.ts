import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";

export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const conn = await db.googleHealthConnection.findUnique({
    where: { userId },
    select: {
      googleEmail: true,
      healthUserId: true,
      lastSyncedAt: true,
    },
  });

  return NextResponse.json({
    connected: Boolean(conn),
    googleEmail: conn?.googleEmail ?? null,
    healthUserId: conn?.healthUserId ?? null,
    lastSynced: conn?.lastSyncedAt?.toISOString() ?? null,
  });
}
