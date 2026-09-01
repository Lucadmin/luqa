import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toHabitDTO } from "@/lib/serializers";
import { createHabitSchema } from "@/lib/validations";

// GET /api/habits — list non-archived habits (full config) for the user.
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const habits = await db.habit.findMany({
    where: { userId, archivedAt: null },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
  });

  return NextResponse.json({ habits: habits.map(toHabitDTO) });
}

// POST /api/habits — create a habit with full goal + schedule config.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createHabitSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;
  const goalType = d.goalType ?? "TASK";

  // A category link only applies to TIME goals; verify ownership.
  let categoryId: string | null = null;
  if (goalType === "TIME" && d.categoryId) {
    const owns = await db.category.findFirst({
      where: { id: d.categoryId, userId },
      select: { id: true },
    });
    if (!owns) {
      return NextResponse.json({ error: "Unknown category" }, { status: 400 });
    }
    categoryId = d.categoryId;
  }

  const count = await db.habit.count({ where: { userId, archivedAt: null } });

  const habit = await db.habit.create({
    data: {
      userId,
      name: d.name,
      icon: d.icon ?? null,
      color: d.color ?? "#f5c451",
      order: count,
      goalType,
      goalPeriod: goalType === "TIME" ? (d.goalPeriod ?? "DAY") : "DAY",
      targetCount: d.targetCount ?? 1,
      targetSeconds: d.targetSeconds ?? 0,
      categoryId,
      scheduleType: d.scheduleType ?? "DAILY",
      weekdays: d.weekdays ?? [],
      weekInterval: d.weekInterval ?? 1,
      intervalDays: d.intervalDays ?? 2,
      intervalFromLastDone: d.intervalFromLastDone ?? false,
      timesPerPeriod: d.timesPerPeriod ?? 3,
      anchorDate: d.anchorDate ?? null,
      dates: d.dates ?? [],
      excludedDates: d.excludedDates ?? [],
    },
  });

  return NextResponse.json({ habit: toHabitDTO(habit) }, { status: 201 });
}
