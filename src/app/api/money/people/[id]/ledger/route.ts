import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toDateKey } from "@/lib/life";
import { toPersonDTO } from "@/lib/serializers";
import type { LedgerItemDTO, PersonLedgerDTO } from "@/lib/types";

// GET /api/money/people/[id]/ledger — one person's whole history with the
// user, plus the balance and treat totals it adds up to.
export async function GET(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;

  const [user, person] = await Promise.all([
    db.user.findUnique({ where: { id: userId }, select: { currency: true } }),
    db.person.findFirst({ where: { id, userId } }),
  ]);
  if (!person) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const [expenses, settlements] = await Promise.all([
    db.expense.findMany({
      where: {
        userId,
        OR: [{ shares: { some: { personId: id } } }, { paidByPersonId: id }],
      },
      orderBy: [{ date: "desc" }, { createdAt: "desc" }],
      include: { shares: true },
    }),
    db.settlement.findMany({
      where: { userId, personId: id },
      orderBy: [{ date: "desc" }, { createdAt: "desc" }],
    }),
  ]);

  const items: LedgerItemDTO[] = [];
  const thisYear = String(new Date().getUTCFullYear());
  let coveredCents = 0;
  let coveredThisYearCents = 0;

  for (const e of expenses) {
    const date = toDateKey(e.date);

    if (e.paidByPersonId === id) {
      // They paid: what the user owes them is the user's own slice. What the
      // others owe on that bill is between them and this person.
      if (e.myShareCents === 0) continue;
      items.push({
        kind: "expense",
        id: e.id,
        date,
        title: e.description || "Expense",
        deltaCents: -e.myShareCents,
        shareCents: e.myShareCents,
        gifted: false,
        amountCents: e.amountCents,
        paidByPersonId: e.paidByPersonId,
        direction: null,
        createdAt: e.createdAt.toISOString(),
      });
      continue;
    }

    // Someone else fronted this one — it never touched the user's balance
    // with this person.
    if (e.paidByPersonId !== null) continue;

    const share = e.shares.find((s) => s.personId === id);
    if (!share) continue;

    if (share.gifted) {
      coveredCents += share.amountCents;
      if (date.startsWith(thisYear)) coveredThisYearCents += share.amountCents;
    }

    items.push({
      kind: "expense",
      id: e.id,
      date,
      title: e.description || "Expense",
      deltaCents: share.gifted ? 0 : share.amountCents,
      shareCents: share.amountCents,
      gifted: share.gifted,
      amountCents: e.amountCents,
      paidByPersonId: null,
      direction: null,
      createdAt: e.createdAt.toISOString(),
    });
  }

  for (const s of settlements) {
    items.push({
      kind: "settlement",
      id: s.id,
      date: toDateKey(s.date),
      title: s.notes || (s.direction === "TO_ME" ? "Paid you back" : "You paid them"),
      deltaCents: s.direction === "TO_ME" ? -s.amountCents : s.amountCents,
      shareCents: s.amountCents,
      gifted: false,
      amountCents: null,
      paidByPersonId: null,
      direction: s.direction,
      createdAt: s.createdAt.toISOString(),
    });
  }

  items.sort((a, b) => b.date.localeCompare(a.date) || b.createdAt.localeCompare(a.createdAt));

  const ledger: PersonLedgerDTO = {
    person: toPersonDTO(person),
    currency: user?.currency ?? "EUR",
    balanceCents: items.reduce((sum, i) => sum + i.deltaCents, 0),
    coveredCents,
    coveredThisYearCents,
    items,
  };

  return NextResponse.json({ ledger });
}
