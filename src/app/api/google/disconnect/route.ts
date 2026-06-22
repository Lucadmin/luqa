import { NextResponse } from "next/server";
import { db } from "@/lib/db";
import { getUserId } from "@/lib/api-auth";
import { makeOAuthClient } from "@/lib/google/oauth";

export async function DELETE() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const conn = await db.googleConnection.findUnique({ where: { userId } });
  if (conn) {
    // Best-effort revoke the token at Google.
    try {
      const client = makeOAuthClient();
      await client.revokeToken(conn.accessToken);
    } catch {
      // Ignore — token may already be expired.
    }
    await db.googleConnection.delete({ where: { userId } });
  }

  return NextResponse.json({ ok: true });
}
