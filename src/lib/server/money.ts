import { db } from "@/lib/db";
import { toDateKey } from "@/lib/life";
import { computeSplit, type SplitParticipant, type SplitShare } from "@/lib/split";
import type { SplitMode } from "@/lib/types";

/** A "YYYY-MM-DD" key as the UTC midnight a `@db.Date` column stores. */
export function dateFromKey(key: string): Date {
  return new Date(`${key}T00:00:00.000Z`);
}

export function todayKey(): string {
  return toDateKey(new Date());
}

export interface PersonTotals {
  /** Positive = they owe the user, negative = the user owes them. */
  balanceCents: number;
  /** All-time treats: recorded against the person, never a debt. */
  coveredCents: number;
  /** Treats within the current calendar year. */
  coveredThisYearCents: number;
  /** "YYYY-MM-DD" of the newest expense or settlement, or null. */
  lastActivity: string | null;
}

function emptyTotals(): PersonTotals {
  return {
    balanceCents: 0,
    coveredCents: 0,
    coveredThisYearCents: 0,
    lastActivity: null,
  };
}

/**
 * Fold every expense and settlement into per-person totals.
 *
 * Read in one round trip and summed in memory rather than through grouped
 * aggregates: a balance has to consider all of history to be correct, and for a
 * personal ledger the whole history is small — far cheaper than four separate
 * round trips to a serverless database.
 *
 * The rules, all from the user's point of view:
 *   · the user paid  → each other participant's share is owed to the user
 *   · someone else paid → only the user's own share matters; what the others
 *     owe in that case is between them and whoever paid
 *   · a gifted share moves no balance, it only adds to "covered"
 *   · a settlement moves the balance back toward zero
 */
export async function loadPersonTotals(
  userId: string,
): Promise<Map<string, PersonTotals>> {
  const [expenses, settlements] = await Promise.all([
    db.expense.findMany({
      where: { userId },
      select: {
        date: true,
        paidByPersonId: true,
        myShareCents: true,
        shares: { select: { personId: true, amountCents: true, gifted: true } },
      },
    }),
    db.settlement.findMany({
      where: { userId },
      select: { personId: true, amountCents: true, direction: true, date: true },
    }),
  ]);

  const totals = new Map<string, PersonTotals>();
  const forPerson = (personId: string) => {
    let t = totals.get(personId);
    if (!t) {
      t = emptyTotals();
      totals.set(personId, t);
    }
    return t;
  };

  const touch = (t: PersonTotals, date: Date) => {
    const key = toDateKey(date);
    if (!t.lastActivity || key > t.lastActivity) t.lastActivity = key;
  };

  const thisYear = String(new Date().getUTCFullYear());

  for (const expense of expenses) {
    if (expense.paidByPersonId === null) {
      for (const share of expense.shares) {
        const t = forPerson(share.personId);
        if (share.gifted) {
          t.coveredCents += share.amountCents;
          if (toDateKey(expense.date).startsWith(thisYear)) {
            t.coveredThisYearCents += share.amountCents;
          }
        } else {
          t.balanceCents += share.amountCents;
        }
        touch(t, expense.date);
      }
    } else {
      const t = forPerson(expense.paidByPersonId);
      t.balanceCents -= expense.myShareCents;
      touch(t, expense.date);
    }
  }

  for (const s of settlements) {
    const t = forPerson(s.personId);
    t.balanceCents += s.direction === "TO_ME" ? -s.amountCents : s.amountCents;
    touch(t, s.date);
  }

  return totals;
}

export type ResolvedSplit =
  | { ok: true; myShareCents: number; shares: SplitShare[] }
  | { ok: false; error: string };

/**
 * Turn the participants a client sent into stored shares. The split is always
 * recomputed here rather than trusted, so the shares in the database can never
 * drift from the rules in split.ts.
 */
export async function resolveSplit({
  userId,
  amountCents,
  splitMode,
  includeMe,
  participants,
  paidByPersonId,
}: {
  userId: string;
  amountCents: number;
  splitMode: SplitMode;
  includeMe: boolean;
  participants: SplitParticipant[];
  paidByPersonId: string | null;
}): Promise<ResolvedSplit> {
  const personIds = participants.map((p) => p.personId);
  if (new Set(personIds).size !== personIds.length) {
    return { ok: false, error: "The same person appears twice on this expense" };
  }

  const ids = new Set(personIds);
  if (paidByPersonId) ids.add(paidByPersonId);

  if (ids.size > 0) {
    const owned = await db.person.count({
      where: { userId, id: { in: [...ids] } },
    });
    if (owned !== ids.size) return { ok: false, error: "Unknown person" };
  }

  // A treat only means something when the user is the one who paid.
  const cleaned = participants.map((p) => ({
    ...p,
    gifted: paidByPersonId === null && p.gifted === true,
  }));

  const split = computeSplit({
    amountCents,
    mode: splitMode,
    includeMe,
    participants: cleaned,
  });

  if (split.overAssigned) {
    return {
      ok: false,
      error:
        splitMode === "PERCENT"
          ? "The shares add up to more than 100%"
          : "The shares add up to more than the total",
    };
  }

  return { ok: true, myShareCents: split.myShareCents, shares: split.shares };
}
