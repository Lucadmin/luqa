import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { createMobileExpenseSchema } from "@/lib/mobile-api-validation";
import { toExpenseDTO } from "@/lib/serializers";
import {
  claimMoneyId,
  dateFromKey,
  expenseLimitFrom,
  listExpenses,
  resolveSplit,
  todayKey,
} from "@/lib/server/money";
import { moneyRoute, readJson, rejected } from "@/lib/server/money-routes";

// GET /api/v1/money/expenses — the bill feed, newest first, optionally
// narrowed to one person or one group.
export const GET = moneyRoute(async (session, request) => {
  const url = new URL(request.url);
  const page = await listExpenses(session.userId, {
    personId: url.searchParams.get("personId"),
    groupId: url.searchParams.get("groupId"),
    cursor: url.searchParams.get("cursor"),
    limit: expenseLimitFrom(url.searchParams.get("limit")),
  });
  if (!page) return rejected("Invalid cursor", "invalid_cursor");
  return mobileJson(page);
});

// POST /api/v1/money/expenses — log a bill and who carries what.
export const POST = moneyRoute(async (session, request) => {
  let body: unknown;
  try {
    body = await readJson(request);
  } catch {
    return invalidJson();
  }
  const parsed = createMobileExpenseSchema.safeParse(body);
  if (!parsed.success) return invalidInput(parsed.error.flatten());
  const { id, ...d } = parsed.data;

  // A create replayed after a lost response answers with the bill that
  // already landed, rather than charging everyone twice.
  const claim = await claimMoneyId(session.userId, id, (candidate) =>
    db.expense.findUnique({
      where: { id: candidate },
      include: { shares: true },
    }),
  );
  if (claim.kind === "replay") {
    return mobileJson({ expense: toExpenseDTO(claim.row) });
  }

  if (d.groupId) {
    const owns = await db.personGroup.findFirst({
      where: { id: d.groupId, userId: session.userId },
      select: { id: true },
    });
    if (!owns) return rejected("Unknown group");
  }

  const split = await resolveSplit({
    userId: session.userId,
    amountCents: d.amountCents,
    splitMode: d.splitMode,
    includeMe: d.includeMe,
    participants: d.participants,
    paidByPersonId: d.paidByPersonId ?? null,
  });
  if (!split.ok) return rejected(split.error);

  const expense = await db.expense.create({
    data: {
      ...(claim.id ? { id: claim.id } : {}),
      userId: session.userId,
      description: d.description,
      amountCents: d.amountCents,
      date: dateFromKey(d.date ?? todayKey()),
      paidByPersonId: d.paidByPersonId ?? null,
      groupId: d.groupId ?? null,
      splitMode: d.splitMode,
      myShareCents: split.myShareCents,
      notes: d.notes,
      shares: {
        create: split.shares.map((s) => ({
          personId: s.personId,
          amountCents: s.amountCents,
          percentBp: s.percentBp,
          gifted: s.gifted,
        })),
      },
    },
    include: { shares: true },
  });

  return mobileJson({ expense: toExpenseDTO(expense) }, { status: 201 });
});
