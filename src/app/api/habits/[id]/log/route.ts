import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { pushEntryUpdate } from "@/lib/google/push-sync";
import { resolveSingleHabitDay } from "@/lib/server/habit-day";
import { habitLogSchema } from "@/lib/validations";

// POST /api/habits/[id]/log — apply a progress action for a given day.
// Actions are validated against the habit's goal type:
//   TASK            → toggle
//   COUNT           → increment | decrement | setCount
//   TIME (unlinked) → start | stop | addSeconds
//   TIME (linked)   → start | stop (creates/stops a real time entry)
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const habit = await db.habit.findFirst({ where: { id, userId } });
  if (!habit) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = habitLogSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: "Invalid input" }, { status: 400 });
  }
  const { date, action, value } = parsed.data;

  const user = await db.user.findUnique({
    where: { id: userId },
    select: { dayStartHour: true, weekStartsOn: true },
  });
  const dayStartHour = user?.dayStartHour ?? 3;
  const weekStartsOn = user?.weekStartsOn ?? 1;
  const now = new Date();

  const bad = () =>
    NextResponse.json({ error: "Action not valid for this habit" }, { status: 400 });

  // ---- TIME (linked to a category): operate on real time entries ----------
  if (habit.goalType === "TIME" && habit.categoryId) {
    if (action === "start") {
      const running = await db.timeEntry.findFirst({
        where: { userId, endTime: null, deletedAt: null },
      });
      // Already timing this category? Leave it. Otherwise start fresh.
      if (!running || running.categoryId !== habit.categoryId) {
        await db.$transaction(async (tx) => {
          await tx.timeEntry.updateMany({
            where: { userId, endTime: null, deletedAt: null },
            data: { endTime: now },
          });
          await tx.timeEntry.create({
            data: {
              userId,
              categoryId: habit.categoryId,
              description: habit.name,
              startTime: now,
              source: "APP",
            },
          });
        });
      }
    } else if (action === "stop") {
      const running = await db.timeEntry.findMany({
        where: { userId, endTime: null, deletedAt: null, categoryId: habit.categoryId },
      });
      for (const e of running) {
        const stopped = await db.timeEntry.update({
          where: { id: e.id },
          data: { endTime: now },
        });
        await pushEntryUpdate(
          userId,
          stopped.id,
          stopped.description,
          stopped.categoryId,
          stopped.startTime.toISOString(),
          stopped.endTime!.toISOString(),
        );
      }
    } else {
      return bad();
    }

    const dto = await resolveSingleHabitDay(userId, habit, date, dayStartHour, weekStartsOn);
    return NextResponse.json({ habit: dto });
  }

  // ---- TASK / COUNT / TIME (unlinked): operate on the habit log -----------
  const log = await db.habitLog.findUnique({
    where: { habitId_date: { habitId: id, date } },
  });
  let count = log?.count ?? 0;
  let seconds = log?.seconds ?? 0;
  let runningSince: Date | null = log?.runningSince ?? null;

  if (habit.goalType === "TASK") {
    if (action !== "toggle") return bad();
    count = count >= 1 ? 0 : 1;
  } else if (habit.goalType === "COUNT") {
    const target = Math.max(1, habit.targetCount);
    if (action === "increment") count = Math.min(target, count + 1);
    else if (action === "decrement") count = Math.max(0, count - 1);
    else if (action === "setCount") count = Math.min(target, Math.max(0, value ?? 0));
    else return bad();
  } else {
    // TIME, unlinked
    if (action === "start") {
      if (!runningSince) runningSince = now;
    } else if (action === "stop") {
      if (runningSince) {
        seconds += Math.max(0, Math.round((now.getTime() - runningSince.getTime()) / 1000));
        runningSince = null;
      }
    } else if (action === "addSeconds") {
      seconds = Math.max(0, seconds + (value ?? 0));
    } else {
      return bad();
    }
  }

  // Recompute completion for the stored progress.
  const done =
    habit.goalType === "TASK"
      ? count >= 1
      : habit.goalType === "COUNT"
        ? count >= Math.max(1, habit.targetCount)
        : seconds >= Math.max(1, habit.targetSeconds);
  const completedAt = done ? (log?.completedAt ?? now) : null;

  await db.habitLog.upsert({
    where: { habitId_date: { habitId: id, date } },
    create: { habitId: id, date, count, seconds, runningSince, completedAt },
    update: { count, seconds, runningSince, completedAt },
  });

  const dto = await resolveSingleHabitDay(userId, habit, date, dayStartHour, weekStartsOn);
  return NextResponse.json({ habit: dto });
}
