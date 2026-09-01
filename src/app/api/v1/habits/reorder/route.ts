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
import { reorderHabitsSchema } from "@/lib/validations";

// POST /api/v1/habits/reorder — persist a new ordering of habit ids.
//
// The whole ordering rather than one habit's new position: the list is short,
// and sending it whole means a replayed write restates the order instead of
// shuffling it again.
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
  const parsed = reorderHabitsSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());

  // Ids this account does not own are dropped rather than refused: the list
  // came off a device whose copy may be a little behind, and reordering the
  // four habits it does know about is the useful half of that request.
  const owned = await db.habit.findMany({
    where: { userId: mobileSession.userId, id: { in: parsed.data.ids } },
    select: { id: true },
  });
  const ownedIds = new Set(owned.map((habit) => habit.id));

  await db.$transaction(
    parsed.data.ids
      .filter((id) => ownedIds.has(id))
      .map((id, order) => db.habit.update({ where: { id }, data: { order } })),
  );

  // The stored order comes back rather than an acknowledgement: a device whose
  // list was short knows immediately where the habits it did not send landed.
  const habits = await db.habit.findMany({
    where: { userId: mobileSession.userId },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
  });
  return mobileJson({ habits: habits.map(toHabitDTO) });
}
