import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { resolveHabitDay } from "@/lib/server/habit-day";

// GET /api/habits/day?date=YYYY-MM-DD
// Habits scheduled on that logical day, each with resolved progress.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const date = new URL(request.url).searchParams.get("date");
  if (!date || !/^\d{4}-\d{2}-\d{2}$/.test(date)) {
    return NextResponse.json({ error: "date required (YYYY-MM-DD)" }, { status: 400 });
  }

  const user = await db.user.findUnique({
    where: { id: userId },
    select: { dayStartHour: true, weekStartsOn: true },
  });

  const habits = await resolveHabitDay(
    userId,
    date,
    user?.dayStartHour ?? 3,
    user?.weekStartsOn ?? 1,
  );

  return NextResponse.json({ date, habits });
}
