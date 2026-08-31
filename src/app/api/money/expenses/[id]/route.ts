import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toExpenseDTO } from "@/lib/serializers";
import { dateFromKey, resolveSplit } from "@/lib/server/money";
import type { SplitParticipant, SplitShare } from "@/lib/split";
import { updateExpenseSchema } from "@/lib/validations";

// PATCH /api/money/expenses/[id] — edit a bill. Anything that can move the
// numbers re-runs the split, so shares never drift out of step with the total.
export async function PATCH(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const existing = await db.expense.findFirst({
    where: { id, userId },
    include: { shares: true },
  });
  if (!existing) return NextResponse.json({ error: "Not found" }, { status: 404 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = updateExpenseSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid input", issues: parsed.error.flatten() },
      { status: 400 },
    );
  }
  const d = parsed.data;

  if (d.groupId) {
    const owns = await db.personGroup.findFirst({
      where: { id: d.groupId, userId },
      select: { id: true },
    });
    if (!owns) return NextResponse.json({ error: "Unknown group" }, { status: 400 });
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
    d.paidByPersonId !== undefined ? (d.paidByPersonId ?? null) : existing.paidByPersonId;

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
      userId,
      amountCents,
      splitMode,
      includeMe: d.includeMe ?? existing.myShareCents > 0,
      participants,
      paidByPersonId,
    });
    if (!split.ok) {
      return NextResponse.json({ error: split.error }, { status: 400 });
    }

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
        ? {
            amountCents,
            splitMode,
            paidByPersonId,
            myShareCents,
          }
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

  return NextResponse.json({ expense: toExpenseDTO(expense) });
}

// DELETE /api/money/expenses/[id] — drop a bill and every share on it.
export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const expense = await db.expense.findFirst({ where: { id, userId } });
  if (!expense) return NextResponse.json({ error: "Not found" }, { status: 404 });

  await db.expense.update({ where: { id }, data: { deletedAt: new Date() } });
  return new NextResponse(null, { status: 204 });
}
