import { db } from "@/lib/db";
import {
  invalidInput,
  invalidJson,
  mobileJson,
} from "@/lib/mobile-api-response";
import { toExpenseDTO } from "@/lib/serializers";
import { dateFromKey, resolveSplit } from "@/lib/server/money";
import {
  moneyRoute,
  notFound,
  readJson,
  rejected,
} from "@/lib/server/money-routes";
import type { SplitParticipant, SplitShare } from "@/lib/split";
import { updateExpenseSchema } from "@/lib/validations";

type Params = { params: Promise<{ id: string }> };

// PATCH /api/v1/money/expenses/[id] — edit a bill. Anything that can move the
// numbers re-runs the split, so shares never drift out of step with the total.
export const PATCH = moneyRoute<[Params]>(
  async (session, request, { params }) => {
    const { id } = await params;
    const existing = await db.expense.findFirst({
      where: { id, userId: session.userId },
      include: { shares: true },
    });
    if (!existing) return notFound();

    let body: unknown;
    try {
      body = await readJson(request);
    } catch {
      return invalidJson();
    }
    const parsed = updateExpenseSchema.safeParse(body);
    if (!parsed.success) return invalidInput(parsed.error.flatten());
    const d = parsed.data;

    if (d.groupId) {
      const owns = await db.personGroup.findFirst({
        where: { id: d.groupId, userId: session.userId },
        select: { id: true },
      });
      if (!owns) return rejected("Unknown group");
    }

    const touchesSplit =
      d.amountCents !== undefined ||
      d.splitMode !== undefined ||
      d.includeMe !== undefined ||
      d.participants !== undefined ||
      d.paidByPersonId !== undefined;

    const amountCents = d.amountCents ?? existing.amountCents;
    const splitMode = d.splitMode ?? existing.splitMode;
    const paidByPersonId =
      d.paidByPersonId !== undefined
        ? (d.paidByPersonId ?? null)
        : existing.paidByPersonId;

    let myShareCents = existing.myShareCents;
    let shares: SplitShare[] | null = null;

    if (touchesSplit) {
      // Fields the caller left out fall back to how the expense already looks.
      const participants: SplitParticipant[] =
        d.participants ??
        existing.shares.map((s) => ({
          personId: s.personId,
          percentBp: s.percentBp,
          amountCents: s.amountCents,
          gifted: s.gifted,
        }));

      const split = await resolveSplit({
        userId: session.userId,
        amountCents,
        splitMode,
        includeMe: d.includeMe ?? existing.myShareCents > 0,
        participants,
        paidByPersonId,
      });
      if (!split.ok) return rejected(split.error);

      myShareCents = split.myShareCents;
      shares = split.shares;
    }

    const expense = await db.expense.update({
      where: { id },
      data: {
        ...(d.description !== undefined ? { description: d.description } : {}),
        ...(d.notes !== undefined ? { notes: d.notes } : {}),
        ...(d.date !== undefined ? { date: dateFromKey(d.date) } : {}),
        ...(d.groupId !== undefined ? { groupId: d.groupId ?? null } : {}),
        ...(touchesSplit
          ? { amountCents, splitMode, paidByPersonId, myShareCents }
          : {}),
        ...(shares
          ? {
              shares: {
                deleteMany: {},
                create: shares.map((s) => ({
                  personId: s.personId,
                  amountCents: s.amountCents,
                  percentBp: s.percentBp,
                  gifted: s.gifted,
                })),
              },
            }
          : {}),
      },
      include: { shares: true },
    });

    return mobileJson({ expense: toExpenseDTO(expense) });
  },
);

// DELETE /api/v1/money/expenses/[id] — drop a bill and every share on it.
//
// Answering 204 for a bill that is already gone keeps a delete replayed from
// a phone's queue from failing permanently on its second attempt.
export const DELETE = moneyRoute<[Params]>(async (session, _request, { params }) => {
  const { id } = await params;
  await db.expense.deleteMany({ where: { id, userId: session.userId } });
  return new Response(null, { status: 204 });
});
