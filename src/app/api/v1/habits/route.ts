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
import { createHabitMobileSchema } from "@/lib/validations";

// GET /api/v1/habits — every habit the account still has, archived included.
//
// The delta feed is how a phone normally stays current. This exists for the
// first read after a sign-in, and for the rare case of a cache that had to be
// thrown away: it is one page, cheap, and needs no cursor to be correct.
export async function GET(request: Request) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  const habits = await db.habit.findMany({
    where: { userId: mobileSession.userId },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
  });
  return mobileJson({ habits: habits.map(toHabitDTO) });
}

// POST /api/v1/habits — create a habit under the id the device already gave it.
export async function POST(request: Request) {
  let mobileSession;
  try {
    mobileSession = await authenticateMobileRequest(request);
  } catch (error) {
    const response = mobileAuthError(error);
    if (response) return response;
    throw error;
  }

  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = createHabitMobileSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const { id, ...input } = parsed.data;
  const userId = mobileSession.userId;

  // A retry after a lost response must not leave two habits behind. The id the
  // device minted is the idempotency key: if it is already here, the create
  // already happened and the row it made is the right answer.
  if (id) {
    const existing = await db.habit.findFirst({ where: { id, userId } });
    if (existing) {
      return mobileJson({ habit: toHabitDTO(existing) }, { status: 200 });
    }
  }

  const goalType = input.goalType ?? "TASK";

  // A category link only means anything for a TIME goal, and only for a
  // category this account owns.
  let categoryId: string | null = null;
  if (goalType === "TIME" && input.categoryId) {
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
    categoryId = input.categoryId;
  }

  const count = await db.habit.count({ where: { userId, archivedAt: null } });
  // Someone else's row already holding this id is not a reason to refuse the
  // habit; it only means the server picks the id instead.
  const taken =
    id !== undefined &&
    (await db.habit.findUnique({ where: { id }, select: { id: true } })) !==
      null;

  const habit = await db.habit.create({
    data: {
      ...(id && !taken ? { id } : {}),
      userId,
      name: input.name,
      icon: input.icon ?? null,
      color: input.color ?? "#f5c451",
      order: count,
      goalType,
      goalPeriod: goalType === "TIME" ? (input.goalPeriod ?? "DAY") : "DAY",
      targetCount: input.targetCount ?? 1,
      targetSeconds: input.targetSeconds ?? 0,
      categoryId,
      scheduleType: input.scheduleType ?? "DAILY",
      weekdays: input.weekdays ?? [],
      weekInterval: input.weekInterval ?? 1,
      intervalDays: input.intervalDays ?? 2,
      timesPerPeriod: input.timesPerPeriod ?? 3,
      anchorDate: input.anchorDate ?? null,
      dates: input.dates ?? [],
      excludedDates: input.excludedDates ?? [],
    },
  });

  return mobileJson({ habit: toHabitDTO(habit) }, { status: 201 });
}
