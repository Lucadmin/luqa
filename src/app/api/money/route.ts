import { NextResponse } from "next/server";
import { getUserId } from "@/lib/api-auth";
import { db } from "@/lib/db";
import { toGroupDTO } from "@/lib/serializers";
import { loadPersonTotals } from "@/lib/server/money";
import type { MoneyOverviewDTO, PersonBalanceDTO } from "@/lib/types";

// GET /api/money — the whole overview screen in one payload: everyone's
// balance, the groups and the headline totals. Expenses are paginated by their
// dedicated endpoint so the screen can keep loading the full history.
export async function GET() {
  const userId = await getUserId();
  if (!userId) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const [user, people, groups, totals] = await Promise.all([
    db.user.findUnique({ where: { id: userId }, select: { currency: true } }),
    db.person.findMany({
      where: { userId },
      orderBy: [{ order: "asc" }, { createdAt: "asc" }],
    }),
    db.personGroup.findMany({
      where: { userId, archivedAt: null },
      orderBy: [{ order: "asc" }, { createdAt: "asc" }],
      include: { members: true },
    }),
    loadPersonTotals(userId),
  ]);

  const balances: PersonBalanceDTO[] = people.map((p) => {
    const t = totals.get(p.id);
    return {
      id: p.id,
      name: p.name,
      color: p.color,
      emoji: p.emoji,
      defaultPercent: p.defaultPercent,
      order: p.order,
      archived: p.archivedAt !== null,
      balanceCents: t?.balanceCents ?? 0,
      coveredCents: t?.coveredCents ?? 0,
      lastActivity: t?.lastActivity ?? null,
    };
  });

  // Whoever owes the most sits at the top; settled people sink to the bottom.
  // Archived people are still sent — they may carry a balance, and their names
  // have to resolve on the expenses they appear in.
  balances.sort(
    (a, b) =>
      Math.abs(b.balanceCents) - Math.abs(a.balanceCents) ||
      a.order - b.order ||
      a.name.localeCompare(b.name),
  );

  const owedToYouCents = balances.reduce(
    (sum, p) => sum + Math.max(0, p.balanceCents),
    0,
  );
  const youOweCents = balances.reduce(
    (sum, p) => sum + Math.max(0, -p.balanceCents),
    0,
  );

  const overview: MoneyOverviewDTO = {
    currency: user?.currency ?? "EUR",
    people: balances,
    groups: groups.map(toGroupDTO),
    owedToYouCents,
    youOweCents,
    netCents: owedToYouCents - youOweCents,
    coveredCents: balances.reduce((sum, p) => sum + p.coveredCents, 0),
  };

  return NextResponse.json({ overview });
}
