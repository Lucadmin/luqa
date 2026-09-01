import { NextResponse } from "next/server";
import type { Prisma } from "@/generated/prisma/client";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toHabitDTO } from "@/lib/serializers";
import { updateHabitSchema } from "@/lib/validations";

// PATCH /api/habits/[id] — update config, reorder, archive or restore.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const existing = await db.habit.findFirst({ where: { id, userId } });
  if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateHabitSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;
  const data: Prisma.HabitUpdateInput = {};

  if (d.name !== undefined) data.name = d.name;
  if (d.icon !== undefined) data.icon = d.icon ?? null;
  if (d.color !== undefined) data.color = d.color;
  if (d.order !== undefined) data.order = d.order;
  if (d.goalType !== undefined) data.goalType = d.goalType;
  if (d.goalPeriod !== undefined) data.goalPeriod = d.goalPeriod;
  if (d.targetCount !== undefined) data.targetCount = d.targetCount;
  if (d.targetSeconds !== undefined) data.targetSeconds = d.targetSeconds;
  if (d.scheduleType !== undefined) data.scheduleType = d.scheduleType;
  if (d.weekdays !== undefined) data.weekdays = d.weekdays;
  if (d.weekInterval !== undefined) data.weekInterval = d.weekInterval;
  if (d.intervalDays !== undefined) data.intervalDays = d.intervalDays;
  if (d.intervalFromLastDone !== undefined) {
    data.intervalFromLastDone = d.intervalFromLastDone;
  }
  if (d.timesPerPeriod !== undefined) data.timesPerPeriod = d.timesPerPeriod;
  if (d.anchorDate !== undefined) data.anchorDate = d.anchorDate ?? null;
  if (d.dates !== undefined) data.dates = d.dates;
  if (d.excludedDates !== undefined) data.excludedDates = d.excludedDates;

  // Category link (TIME goals). Resolve against the effective goal type.
  const effectiveGoal = d.goalType ?? existing.goalType;
  if (d.categoryId !== undefined) {
    if (effectiveGoal === "TIME" && d.categoryId) {
      const owns = await db.category.findFirst({
        where: { id: d.categoryId, userId },
        select: { id: true },
      });
      if (!owns) {
        return NextResponse.json({ error: "Unknown category" }, { status: 400 });
      }
      data.category = { connect: { id: d.categoryId } };
    } else {
      data.category = { disconnect: true };
    }
  } else if (d.goalType !== undefined && d.goalType !== "TIME") {
    // Switching away from a TIME goal drops any stale link.
    data.category = { disconnect: true };
  }

  if (d.archived !== undefined) {
    data.archivedAt = d.archived ? new Date() : null;
  }

  const habit = await db.habit.update({ where: { id }, data });
  return NextResponse.json({ habit: toHabitDTO(habit) });
}

// DELETE /api/habits/[id] — archive a habit (soft delete).
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const habit = await db.habit.findFirst({ where: { id, userId } });
  if (!habit) return NextResponse.json({ error: "Not found" }, { status: 404 });

  await db.habit.update({ where: { id }, data: { archivedAt: new Date() } });
  return new NextResponse(null, { status: 204 });
}
