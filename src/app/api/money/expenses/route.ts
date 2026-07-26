import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toExpenseDTO } from "@/lib/serializers";
import { dateFromKey, resolveSplit, todayKey } from "@/lib/server/money";
import { createExpenseSchema } from "@/lib/validations";

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

interface ExpenseCursor {
  date: string;
  createdAt: string;
  id: string;
}

function encodeCursor(cursor: ExpenseCursor): string {
  return Buffer.from(JSON.stringify(cursor)).toString("base64url");
}

function decodeCursor(value: string): ExpenseCursor | null {
  try {
    const parsed = JSON.parse(
      Buffer.from(value, "base64url").toString("utf8"),
    ) as Partial<ExpenseCursor>;

    if (
      typeof parsed.date !== "string" ||
      typeof parsed.createdAt !== "string" ||
      typeof parsed.id !== "string" ||
      parsed.id.length === 0 ||
      Number.isNaN(Date.parse(parsed.date)) ||
      Number.isNaN(Date.parse(parsed.createdAt))
    ) {
      return null;
    }

    return {
      date: parsed.date,
      createdAt: parsed.createdAt,
      id: parsed.id,
    };
  } catch {
    return null;
  }
}

// GET /api/money/expenses — newest first, optionally narrowed to one person or
// one group. The opaque cursor keeps ordering stable even when several bills
// share a date.
export async function GET(request: Request) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const url = new URL(request.url);
  const personId = url.searchParams.get("personId");
  const groupId = url.searchParams.get("groupId");
  const cursorParam = url.searchParams.get("cursor");
  const cursor = cursorParam ? decodeCursor(cursorParam) : null;
  if (cursorParam && !cursor) {
    return NextResponse.json({ error: "Invalid cursor" }, { status: 400 });
  }
  const requestedLimit = Number(url.searchParams.get("limit"));
  const limit = Math.min(
    MAX_LIMIT,
    Math.max(
      1,
      Number.isFinite(requestedLimit) && requestedLimit > 0
        ? Math.trunc(requestedLimit)
        : DEFAULT_LIMIT,
    ),
  );

  const filters = [
    ...(personId
      ? [
          {
            OR: [
              { shares: { some: { personId } } },
              { paidByPersonId: personId },
            ],
          },
        ]
      : []),
    ...(cursor
      ? [
          {
            OR: [
              { date: { lt: new Date(cursor.date) } },
              {
                date: new Date(cursor.date),
                createdAt: { lt: new Date(cursor.createdAt) },
              },
              {
                date: new Date(cursor.date),
                createdAt: new Date(cursor.createdAt),
                id: { lt: cursor.id },
              },
            ],
          },
        ]
      : []),
  ];

  const expenses = await db.expense.findMany({
    where: {
      userId,
      ...(groupId ? { groupId } : {}),
      ...(filters.length > 0 ? { AND: filters } : {}),
    },
    orderBy: [{ date: "desc" }, { createdAt: "desc" }, { id: "desc" }],
    take: limit + 1,
    include: { shares: true },
  });

  const page = expenses.slice(0, limit);
  const last = page.at(-1);
  const nextCursor =
    expenses.length > limit && last
      ? encodeCursor({
          date: last.date.toISOString(),
          createdAt: last.createdAt.toISOString(),
          id: last.id,
        })
      : null;

  return NextResponse.json({
    expenses: page.map(toExpenseDTO),
    nextCursor,
  });
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
