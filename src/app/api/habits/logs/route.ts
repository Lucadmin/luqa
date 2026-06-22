import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { z } from "zod";

// GET /api/habits/logs?date=YYYY-MM-DD
// Returns the set of habit IDs that have a log on that date.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const date = new URL(request.url).searchParams.get("date");
  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json({ error: "date required (YYYY-MM-DD)" }, { status: 400 });
  }

  const logs = await db.habitLog.findMany({
    where: { habit: { userId }, date },
    select: { habitId: true },
  });

  return NextResponse.json({ logged: logs.map((l) => l.habitId) });
}

const toggleSchema = z.object({
  habitId: z.string(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
});

// POST /api/habits/logs — toggle a habit completion on a date
// Creates the log if it doesn't exist, deletes it if it does.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try { body = await request.json(); } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = toggleSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const { habitId, date } = parsed.data;

  // Verify ownership
  const habit = await db.habit.findFirst({ where: { id: habitId, userId } });
  if (!habit) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const existing = await db.habitLog.findUnique({
    where: { habitId_date: { habitId, date } },
  });

  if (existing) {
    await db.habitLog.delete({ where: { id: existing.id } });
    return NextResponse.json({ done: false });
  } else {
    await db.habitLog.create({ data: { habitId, date } });
    return NextResponse.json({ done: true });
  }
}
