import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { createMobilePersonSchema } from "@/lib/mobile-api-validation";
import { toPersonDTO } from "@/lib/serializers";
import { claimMoneyId } from "@/lib/server/money";
import { moneyRoute, readJson } from "@/lib/server/money-routes";
import { reviveDeletedPerson } from "@/lib/server/tombstones";

// GET /api/v1/money/people — everyone, archived included, in display order.
export const GET = moneyRoute(async (session) => {
  const people = await db.person.findMany({
    where: { userId: session.userId },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
  });
  return mobileJson({ people: people.map(toPersonDTO) });
});

// POST /api/v1/money/people — add someone to split with.
export const POST = moneyRoute(async (session, request) => {
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = createMobilePersonSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const { id, ...d } = parsed.data;

  const claim = await claimMoneyId(session.userId, id, (candidate) =>
    db.person.findUnique({ where: { id: candidate } }),
  );
  if (claim.kind === "replay") {
    return mobileJson({ person: toPersonDTO(claim.row) });
  }

  // A person is identified by their name, so adding one this account already
  // has answers with that row rather than colliding on the unique key. The
  // browser refuses a duplicate name; a phone must not, because the same
  // "Mira" added offline on two devices has to converge on one person rather
  // than stranding a write nothing can ever replay.
  const existing = await db.person.findFirst({
    where: { userId: session.userId, name: d.name },
  });
  if (existing) return mobileJson({ person: toPersonDTO(existing) });

  // The name may still be held by someone this account deleted. Bringing them
  // back is both what the user means and the only way past the unique key.
  const revived = await reviveDeletedPerson(session.userId, d.name);
  if (revived) return mobileJson({ person: toPersonDTO(revived) });

  const count = await db.person.count({ where: { userId: session.userId } });
  const person = await db.person.create({
    data: {
      ...(claim.id ? { id: claim.id } : {}),
      userId: session.userId,
      name: d.name,
      color: d.color ?? "#6366f1",
      emoji: d.emoji ?? null,
      defaultPercent: d.defaultPercent ?? null,
      order: count,
    },
  });

  return mobileJson({ person: toPersonDTO(person) }, { status: 201 });
});
