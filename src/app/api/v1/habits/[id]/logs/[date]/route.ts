import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileAuthError,
  mobileJson,
  readJson,
} from "@/lib/mobile-api-response";
import { toHabitLogDTO } from "@/lib/serializers";
import { authenticateMobileRequest } from "@/lib/server/mobile-auth";
import { putHabitLogSchema } from "@/lib/validations";

const DATE_KEY = /^\d{4}-\d{2}-\d{2}$/;

// PUT /api/v1/habits/[id]/logs/[date] — a day's progress, as the device
// resolved it.
//
// Deliberately a PUT of state rather than a POST of an action. The web client
// says "increment" and lets the server add one; a queued write cannot, because
// a retry after a lost response would add one twice. The phone already knows
// what the day looks like — it resolves habits locally — so it sends the
// numbers, and replaying the write lands on the same numbers.
export async function PUT(
  request: Request,
  { params }: { params: Promise<{ id: string; date: string }> },
) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  const { id, date } = await params;
  if (!DATE_KEY.test(date)) {
    return mobileJson(
      {
        error: {
          code: "invalid_date",
          message: "Expected a YYYY-MM-DD logical day",
        },
      },
      { status: 400 },
    );
  }

  const habit = await db.habit.findFirst({
    where: { id, userId: mobileSession.userId },
  });
  if (!habit) {
    return mobileJson(
      { error: { code: "not_found", message: "Habit not found" } },
      { status: 404 },
    );
  }

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = putHabitLogSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const { count, seconds } = parsed.data;
  const runningSince = parsed.data.runningSince
    ? new Date(parsed.data.runningSince)
    : null;

  // Completion is recomputed here rather than trusted from the request: it is
  // what streaks are counted from, and the two clients must agree on it even
  // when one of them is an older build.
  const done =
    habit.goalType === "TASK"
      ? count >= 1
      : habit.goalType === "COUNT"
        ? count >= Math.max(1, habit.targetCount)
        : seconds >= Math.max(1, habit.targetSeconds);

  const existing = await db.habitLog.findUnique({
    where: { habitId_date: { habitId: id, date } },
  });
  // The first moment the goal was met is kept once it is known. Adding a
  // seventh glass of water does not re-complete the day.
  const completedAt = done ? (existing?.completedAt ?? new Date()) : null;

  const log = await db.habitLog.upsert({
    where: { habitId_date: { habitId: id, date } },
    create: { habitId: id, date, count, seconds, runningSince, completedAt },
    update: { count, seconds, runningSince, completedAt },
  });

  return mobileJson({ log: toHabitLogDTO(log) });
}
