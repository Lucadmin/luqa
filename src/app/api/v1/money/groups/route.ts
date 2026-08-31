import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { createMobileGroupSchema } from "@/lib/mobile-api-validation";
import { toGroupDTO } from "@/lib/serializers";
import { claimMoneyId } from "@/lib/server/money";
import { moneyRoute, readJson, rejected } from "@/lib/server/money-routes";
import { reviveDeletedGroup } from "@/lib/server/tombstones";

// GET /api/v1/money/groups — the user's groups with their member ids.
export const GET = moneyRoute(async (session) => {
  const groups = await db.personGroup.findMany({
    where: { userId: session.userId },
    orderBy: [{ order: "asc" }, { createdAt: "asc" }],
    include: { members: true },
  });
  return mobileJson({ groups: groups.map(toGroupDTO) });
});

// POST /api/v1/money/groups — create a group from a set of people.
export const POST = moneyRoute(async (session, request) => {
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = createMobileGroupSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const { id, ...d } = parsed.data;

  const claim = await claimMoneyId(session.userId, id, (candidate) =>
    db.personGroup.findUnique({
      where: { id: candidate },
      include: { members: true },
    }),
  );
  if (claim.kind === "replay") {
    return mobileJson({ group: toGroupDTO(claim.row) });
  }

  const memberIds = [...new Set(d.memberIds)];
  if (memberIds.length > 0) {
    const owned = await db.person.count({
      where: { userId: session.userId, id: { in: memberIds } },
    });
    if (owned !== memberIds.length) return rejected("Unknown person");
  }

  // Like people: a name that already exists is the same group, not a refusal.
  const existing = await db.personGroup.findFirst({
    where: { userId: session.userId, name: d.name },
    include: { members: true },
  });
  if (existing) return mobileJson({ group: toGroupDTO(existing) });

  const revived = await reviveDeletedGroup(session.userId, d.name);
  if (revived) return mobileJson({ group: toGroupDTO(revived) });

  const count = await db.personGroup.count({
    where: { userId: session.userId },
  });
  const group = await db.personGroup.create({
    data: {
      ...(claim.id ? { id: claim.id } : {}),
      userId: session.userId,
      name: d.name,
      color: d.color ?? "#6366f1",
      emoji: d.emoji ?? null,
      order: count,
      members: { create: memberIds.map((personId) => ({ personId })) },
    },
    include: { members: true },
  });

  return mobileJson({ group: toGroupDTO(group) }, { status: 201 });
});
