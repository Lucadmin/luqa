import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toExpenseDTO } from "@/lib/serializers";
import { dateFromKey, resolveSplit, todayKey } from "@/lib/server/money";
import { createExpenseSchema } from "@/lib/validations";

const DEFAULT_LIMIT = 50;
const MAX_LIMIT = 200;

// GET /api/money/expenses — newest first, optionally narrowed to one person or
// one group.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const url = new URL(request.url);
  const personId = url.searchParams.get("personId");
  const groupId = url.searchParams.get("groupId");
  const limit = Math.min(
    MAX_LIMIT,
    Math.max(1, Number(url.searchParams.get("limit")) || DEFAULT_LIMIT),
  );

  const expenses = await db.expense.findMany({
    where: {
      userId,
      ...(groupId ? { groupId } : {}),
      ...(personId
        ? {
            OR: [
              { shares: { some: { personId } } },
              { paidByPersonId: personId },
            ],
          }
        : {}),
    },
    orderBy: [{ date: "desc" }, { createdAt: "desc" }],
    take: limit,
    include: { shares: true },
  });

  return NextResponse.json({ expenses: expenses.map(toExpenseDTO) });
}

// POST /api/money/expenses — log a bill and who carries what.
export async function POST(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = createExpenseSchema.safeParse(body);
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

  const split = await resolveSplit({
    userId,
    amountCents: d.amountCents,
    splitMode: d.splitMode,
    includeMe: d.includeMe,
    participants: d.participants,
    paidByPersonId: d.paidByPersonId ?? null,
  });
  if (!split.ok) {
    return NextResponse.json({ error: split.error }, { status: 400 });
  }

  const expense = await db.expense.create({
    data: {
      userId,
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

  return NextResponse.json({ expense: toExpenseDTO(expense) }, { status: 201 });
}
