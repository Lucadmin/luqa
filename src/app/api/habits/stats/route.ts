import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { addDays, daysBetween, goalFraction, isScheduledOn } from "@/lib/habits";
import { habitGoal, habitSchedule } from "@/lib/server/habit-day";
import type { HabitStatDTO } from "@/lib/types";

/** UTC logical-day key for an instant, consistent with the day window. */
function logicalKeyUTC(d: Date, dayStartHour: number): string {
  const t = new Date(d.getTime() - dayStartHour * 3_600_000);
  const y = t.getUTCFullYear();
  const m = String(t.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(t.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${dd}`;
}

// GET /api/habits/stats?from=YYYY-MM-DD&to=YYYY-MM-DD
// Per-habit completion fractions across the range, plus streak analytics.
// `to` is treated as "today" for streak / pending purposes.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { searchParams } = new URL(request.url);
  const from = searchParams.get("from");
  const to = searchParams.get("to");
  const re = /^\d{4}-\d{2}-\d{2}$/;
  if (!from || !to || !re.test(from) || !re.test(to) || from > to) {
    return NextResponse.json({ error: "valid from/to required" }, { status: 400 });
  }
  if (daysBetween(from, to) > 400) {
    return NextResponse.json({ error: "Range too large" }, { status: 400 });
  }

  const [habits, user] = await Promise.all([
    db.habit.findMany({
      where: { userId, archivedAt: null },
      orderBy: [{ order: "asc" }, { createdAt: "asc" }],
    }),
    db.user.findUnique({
      where: { id: userId },
      select: { dayStartHour: true, weekStartsOn: true },
    }),
  ]);
  const dayStartHour = user?.dayStartHour ?? 3;
  const weekStartsOn = user?.weekStartsOn ?? 1;

  if (habits.length === 0) return NextResponse.json({ stats: [] });

  // Logs for the range, keyed habitId|date.
  const logs = await db.habitLog.findMany({
    where: { habitId: { in: habits.map((h) => h.id) }, date: { gte: from, lte: to } },
  });
  const logByKey = new Map(logs.map((l) => [`${l.habitId}|${l.date}`, l]));

  // Per-day tracked seconds for linked-TIME habits' categories.
  const linkedCatIds = [
    ...new Set(
      habits
        .filter((h) => h.goalType === "TIME" && h.categoryId)
        .map((h) => h.categoryId as string),
    ),
  ];
  const secByCatDay = new Map<string, number>();
  if (linkedCatIds.length > 0) {
    const start = new Date(`${from}T00:00:00.000Z`);
    start.setUTCHours(dayStartHour, 0, 0, 0);
    const end = new Date(`${to}T00:00:00.000Z`);
    end.setUTCHours(dayStartHour + 24, 0, 0, 0);
    const entries = await db.timeEntry.findMany({
      where: {
        userId,
        deletedAt: null,
        categoryId: { in: linkedCatIds },
        startTime: { gte: start, lt: end },
        endTime: { not: null },
      },
      select: { categoryId: true, startTime: true, endTime: true },
    });
    for (const e of entries) {
      if (!e.categoryId || !e.endTime) continue;
      const key = `${e.categoryId}|${logicalKeyUTC(e.startTime, dayStartHour)}`;
      const secs = Math.max(0, Math.round((e.endTime.getTime() - e.startTime.getTime()) / 1000));
      secByCatDay.set(key, (secByCatDay.get(key) ?? 0) + secs);
    }
  }

  const fractionFor = (h: (typeof habits)[number], dateKey: string): number => {
    if (h.goalType === "TIME" && h.categoryId) {
      const seconds = secByCatDay.get(`${h.categoryId}|${dateKey}`) ?? 0;
      return goalFraction(habitGoal(h), { count: 0, seconds });
    }
    const log = logByKey.get(`${h.id}|${dateKey}`);
    return goalFraction(habitGoal(h), {
      count: log?.count ?? 0,
      seconds: log?.seconds ?? 0,
    });
  };

  const stats: HabitStatDTO[] = habits.map((h) => {
    const sched = habitSchedule(h);
    const fractions: Record<string, number> = {};
    let completed = 0;
    let scheduled = 0;
    let bestStreak = 0;
    let run = 0;

    for (let day = from; day <= to; day = addDays(day, 1)) {
      if (!isScheduledOn(sched, day, weekStartsOn)) continue;
      const f = fractionFor(h, day);
      fractions[day] = f;
      scheduled += 1;
      if (f >= 1) {
        completed += 1;
        run += 1;
        bestStreak = Math.max(bestStreak, run);
      } else {
        run = 0;
      }
    }

    // Current streak counting back from `to` (today). A pending today doesn't break.
    let streak = 0;
    let allowPending = true;
    for (let day = to; day >= from; day = addDays(day, -1)) {
      if (!isScheduledOn(sched, day, weekStartsOn)) continue;
      const done = (fractions[day] ?? 0) >= 1;
      if (done) {
        streak += 1;
      } else if (day === to && allowPending) {
        allowPending = false; // today not done yet — skip without breaking
      } else {
        break;
      }
    }

    return { habitId: h.id, fractions, streak, bestStreak, completed, scheduled };
  });

  return NextResponse.json({ stats });
}
