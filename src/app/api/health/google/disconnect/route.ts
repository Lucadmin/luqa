import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";

export async function DELETE() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  await db.googleHealthConnection.deleteMany({ where: { userId } });
  return NextResponse.json({ ok: true });
}
