import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { createMobileSettlementSchema } from "@/lib/mobile-api-validation";
import { toSettlementDTO } from "@/lib/serializers";
import { claimMoneyId, dateFromKey, todayKey } from "@/lib/server/money";
import { moneyRoute, readJson, rejected } from "@/lib/server/money-routes";

// GET /api/v1/money/settlements?personId= — paybacks, newest first.
export const GET = moneyRoute(async (session, request) => {
  const personId = new URL(request.url).searchParams.get("personId");
  const settlements = await db.settlement.findMany({
    where: { userId: session.userId, ...(personId ? { personId } : {}) },
    orderBy: [{ date: "desc" }, { createdAt: "desc" }],
    take: 100,
  });
  return mobileJson({ settlements: settlements.map(toSettlementDTO) });
});

// POST /api/v1/money/settlements — record a payback. It moves the balance
// without touching any of the expenses behind it, so history stays readable.
export const POST = moneyRoute(async (session, request) => {
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = createMobileSettlementSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const { id, ...d } = parsed.data;

  // Without this, a payback whose response was lost is recorded twice and the
  // balance overshoots past zero.
  const claim = await claimMoneyId(session.userId, id, (candidate) =>
    db.settlement.findUnique({ where: { id: candidate } }),
  );
  if (claim.kind === "replay") {
    return mobileJson({ settlement: toSettlementDTO(claim.row) });
  }

  const person = await db.person.findFirst({
    where: { id: d.personId, userId: session.userId },
    select: { id: true },
  });
  if (!person) return rejected("Unknown person");

  const settlement = await db.settlement.create({
    data: {
      ...(claim.id ? { id: claim.id } : {}),
      userId: session.userId,
      personId: d.personId,
      amountCents: d.amountCents,
      direction: d.direction,
      date: dateFromKey(d.date ?? todayKey()),
      notes: d.notes,
    },
  });

  return mobileJson({ settlement: toSettlementDTO(settlement) }, { status: 201 });
});
