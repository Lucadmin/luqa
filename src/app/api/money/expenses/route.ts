import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toExpenseDTO } from "@/lib/serializers";
import {
  dateFromKey,
  expenseLimitFrom,
  listExpenses,
  resolveSplit,
  todayKey,
} from "@/lib/server/money";
import { createExpenseSchema } from "@/lib/validations";

// GET /api/money/expenses — newest first, optionally narrowed to one person or
// one group. The opaque cursor keeps ordering stable even when several bills
// share a date.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const url = new URL(request.url);
  const page = await listExpenses(userId, {
    personId: url.searchParams.get("personId"),
    groupId: url.searchParams.get("groupId"),
    cursor: url.searchParams.get("cursor"),
    limit: expenseLimitFrom(url.searchParams.get("limit")),
  });
  if (!page) return NextResponse.json({ error: "Invalid cursor" }, { status: 400 });

  return NextResponse.json(page);
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
