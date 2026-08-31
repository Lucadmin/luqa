import { db } from "@/lib/db";
import { toDateKey } from "@/lib/life";
import { toExpenseDTO, toGroupDTO, toPersonDTO } from "@/lib/serializers";
import { computeSplit, type SplitParticipant, type SplitShare } from "@/lib/split";
import type {
  ExpensePageDTO,
  LedgerItemDTO,
  MoneyOverviewDTO,
  PersonBalanceDTO,
  PersonLedgerDTO,
  SplitMode,
} from "@/lib/types";

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

/**
 * The whole money screen in one payload: everyone's balance, the groups, and
 * the headline totals.
 *
 * Shared by the browser route and the mobile contract so the two can never
 * disagree about what a balance is.
 */
export async function moneyOverview(userId: string): Promise<MoneyOverviewDTO> {
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
      ...toPersonDTO(p),
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

  return {
    currency: user?.currency ?? "EUR",
    people: balances,
    groups: groups.map(toGroupDTO),
    owedToYouCents,
    youOweCents,
    netCents: owedToYouCents - youOweCents,
    coveredCents: balances.reduce((sum, p) => sum + p.coveredCents, 0),
  };
}

/**
 * One person's whole history with the user, plus the balance and treat totals
 * it adds up to. Null when the person is not the user's.
 */
export async function personLedger(
  userId: string,
  personId: string,
): Promise<PersonLedgerDTO | null> {
  const [user, person] = await Promise.all([
    db.user.findUnique({ where: { id: userId }, select: { currency: true } }),
    db.person.findFirst({ where: { id: personId, userId } }),
  ]);
  if (!person) return null;

  const [expenses, settlements] = await Promise.all([
    db.expense.findMany({
      where: {
        userId,
        OR: [
          { shares: { some: { personId } } },
          { paidByPersonId: personId },
        ],
      },
      orderBy: [{ date: "desc" }, { createdAt: "desc" }],
      include: { shares: true },
    }),
    db.settlement.findMany({
      where: { userId, personId },
      orderBy: [{ date: "desc" }, { createdAt: "desc" }],
    }),
  ]);

  const items: LedgerItemDTO[] = [];
  const thisYear = String(new Date().getUTCFullYear());
  let coveredCents = 0;
  let coveredThisYearCents = 0;

  for (const e of expenses) {
    const date = toDateKey(e.date);

    if (e.paidByPersonId === personId) {
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
        expense: toExpenseDTO(e),
        createdAt: e.createdAt.toISOString(),
      });
      continue;
    }

    // Someone else fronted this one — it never touched the user's balance
    // with this person.
    if (e.paidByPersonId !== null) continue;

    const share = e.shares.find((s) => s.personId === personId);
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
      expense: toExpenseDTO(e),
      createdAt: e.createdAt.toISOString(),
    });
  }

  for (const s of settlements) {
    items.push({
      kind: "settlement",
      id: s.id,
      date: toDateKey(s.date),
      title:
        s.notes || (s.direction === "TO_ME" ? "Paid you back" : "You paid them"),
      deltaCents: s.direction === "TO_ME" ? -s.amountCents : s.amountCents,
      shareCents: s.amountCents,
      gifted: false,
      amountCents: null,
      paidByPersonId: null,
      direction: s.direction,
      expense: null,
      createdAt: s.createdAt.toISOString(),
    });
  }

  items.sort(
    (a, b) =>
      b.date.localeCompare(a.date) || b.createdAt.localeCompare(a.createdAt),
  );

  return {
    person: toPersonDTO(person),
    currency: user?.currency ?? "EUR",
    balanceCents: items.reduce((sum, i) => sum + i.deltaCents, 0),
    coveredCents,
    coveredThisYearCents,
    items,
  };
}

// --- The expense feed ---

const DEFAULT_EXPENSE_LIMIT = 20;
const MAX_EXPENSE_LIMIT = 100;

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

    return { date: parsed.date, createdAt: parsed.createdAt, id: parsed.id };
  } catch {
    return null;
  }
}

export function expenseLimitFrom(raw: string | null): number {
  const requested = Number(raw);
  return Math.min(
    MAX_EXPENSE_LIMIT,
    Math.max(
      1,
      Number.isFinite(requested) && requested > 0
        ? Math.trunc(requested)
        : DEFAULT_EXPENSE_LIMIT,
    ),
  );
}

/**
 * One page of bills, newest first, optionally narrowed to a person or a group.
 *
 * The cursor is opaque and carries date, createdAt and id together, so the
 * ordering stays stable even when several bills share a date. Returns null
 * when a cursor was supplied that this server did not mint.
 */
export async function listExpenses(
  userId: string,
  {
    personId,
    groupId,
    cursor: cursorParam,
    limit,
  }: {
    personId?: string | null;
    groupId?: string | null;
    cursor?: string | null;
    limit: number;
  },
): Promise<ExpensePageDTO | null> {
  const cursor = cursorParam ? decodeCursor(cursorParam) : null;
  if (cursorParam && !cursor) return null;

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

  return {
    expenses: page.map(toExpenseDTO),
    nextCursor:
      expenses.length > limit && last
        ? encodeCursor({
            date: last.date.toISOString(),
            createdAt: last.createdAt.toISOString(),
            id: last.id,
          })
        : null,
  };
}

// --- Client-minted identities ---

/** The client's id already belongs to a row on another account. */
export class MoneyIdConflictError extends Error {
  constructor() {
    super("That id is already in use");
    this.name = "MoneyIdConflictError";
  }
}

type OwnedRow = { id: string; userId: string };

/**
 * Decides what a create carrying a client-minted [id] should do.
 *
 * - `replay`  — this account already has that row; answer with it untouched,
 *               which is what a create retried after a lost response needs.
 * - `use`     — the id is free, so honour it.
 * - throws    — the id belongs to somebody else, which the client must not be
 *               allowed to probe for or overwrite.
 */
export async function claimMoneyId<T extends OwnedRow>(
  userId: string,
  id: string | undefined,
  find: (id: string) => Promise<T | null>,
): Promise<{ kind: "replay"; row: T } | { kind: "use"; id?: string }> {
  if (id === undefined) return { kind: "use" };
  const existing = await find(id);
  if (!existing) return { kind: "use", id };
  if (existing.userId !== userId) throw new MoneyIdConflictError();
  return { kind: "replay", row: existing };
}
