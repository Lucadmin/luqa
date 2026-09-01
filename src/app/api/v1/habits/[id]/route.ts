import type { Prisma } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { toHabitDTO } from "@/lib/serializers";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { updateHabitSchema } from "@/lib/validations";

function notFound() {
  return mobileJson(
    { error: { code: "not_found", message: "Habit not found" } },
    { status: 404 },
  );
}

// PATCH /api/v1/habits/[id] — change a habit's goal, schedule, or archived state.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
  const userId = mobileSession.userId;
  const { id } = await params;
  const existing = await db.habit.findFirst({ where: { id, userId } });
  if (!existing) return notFound();

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = updateHabitSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const input = parsed.data;

  const data: Prisma.HabitUpdateInput = {};
  if (input.name !== undefined) data.name = input.name;
  if (input.icon !== undefined) data.icon = input.icon ?? null;
  if (input.color !== undefined) data.color = input.color;
  if (input.order !== undefined) data.order = input.order;
  if (input.goalType !== undefined) data.goalType = input.goalType;
  if (input.goalPeriod !== undefined) data.goalPeriod = input.goalPeriod;
  if (input.targetCount !== undefined) data.targetCount = input.targetCount;
  if (input.targetSeconds !== undefined) {
    data.targetSeconds = input.targetSeconds;
  }
  if (input.scheduleType !== undefined) data.scheduleType = input.scheduleType;
  if (input.weekdays !== undefined) data.weekdays = input.weekdays;
  if (input.weekInterval !== undefined) data.weekInterval = input.weekInterval;
  if (input.intervalDays !== undefined) data.intervalDays = input.intervalDays;
  if (input.timesPerPeriod !== undefined) {
    data.timesPerPeriod = input.timesPerPeriod;
  }
  if (input.anchorDate !== undefined) data.anchorDate = input.anchorDate ?? null;
  if (input.dates !== undefined) data.dates = input.dates;
  if (input.excludedDates !== undefined) {
    data.excludedDates = input.excludedDates;
  }

  // The link is resolved against the goal type the habit will have once this
  // write lands, not the one it had before it.
  const effectiveGoal = input.goalType ?? existing.goalType;
  if (input.categoryId !== undefined) {
    if (effectiveGoal === "TIME" && input.categoryId) {
      const owns = await db.category.findFirst({
        where: { id: input.categoryId, userId },
        select: { id: true },
      });
      if (!owns) {
        return mobileJson(
          { error: { code: "unknown_category", message: "Unknown category" } },
          { status: 400 },
        );
      }
      data.category = { connect: { id: input.categoryId } };
    } else {
      data.category = { disconnect: true };
    }
  } else if (input.goalType !== undefined && input.goalType !== "TIME") {
    // Leaving TIME behind takes the category link with it, rather than leaving
    // a link nothing reads.
    data.category = { disconnect: true };
  }

  if (input.archived !== undefined) {
    data.archivedAt = input.archived ? new Date() : null;
  }

  const habit = await db.habit.update({ where: { id }, data });
  return mobileJson({ habit: toHabitDTO(habit) });
}

// DELETE /api/v1/habits/[id] — archive the habit.
//
// Habits are archived rather than removed, here as on the web: the logs behind
// one are the record of a stretch of someone's life, and a streak that can be
// deleted by accident is worse than a list that needs tidying.
export async function DELETE(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }
  const { id } = await params;
  const existing = await db.habit.findFirst({
    where: { id, userId: mobileSession.userId },
    select: { id: true, archivedAt: true },
  });
  // Archiving something already archived is the state the caller asked for, so
  // a replayed delete succeeds rather than 404ing the queue into a discard.
  if (!existing) return notFound();
  if (existing.archivedAt === null) {
    await db.habit.update({
      where: { id },
      data: { archivedAt: new Date() },
    });
  }
  return new Response(null, { status: 204 });
}
