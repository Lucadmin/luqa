"use client";

import { Gift, Plus, Users, Wallet } from "lucide-react";
import dynamic from "next/dynamic";
import { useMemo, useState } from "react";
import { Avatar } from "@/components/money/avatar";
import { balanceLabel } from "@/components/money/person-sheet";
import { AppPage, AppPageHeader } from "@/components/ui/app-page";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { InfiniteListFooter } from "@/components/ui/infinite-list-footer";
import { useExpenses, useMoneyOverview } from "@/lib/client/use-money";
import { cn } from "@/lib/cn";
import { formatMoney } from "@/lib/money";
import { formatDayLabel } from "@/lib/time";
import type { ExpenseDTO, PersonBalanceDTO } from "@/lib/types";

// Modals only matter once opened — load them on demand instead of paying
// for their JS on every visit to the money tab.
const ExpenseSheet = dynamic(() =>
  import("@/components/money/expense-sheet").then((m) => m.ExpenseSheet),
);
const GroupsSheet = dynamic(() =>
  import("@/components/money/groups-sheet").then((m) => m.GroupsSheet),
);
const PersonSheet = dynamic(() =>
  import("@/components/money/person-sheet").then((m) => m.PersonSheet),
);

type MoneyOverlay =
  | {
      type: "expense";
      expense: ExpenseDTO | null;
      personIds: string[];
      groupId: string | null;
    }
  | { type: "person"; personId: string }
  | { type: "groups" }
  | null;

const EMPTY_PEOPLE: PersonBalanceDTO[] = [];

export function MoneyView() {
  const { overview, isLoading } = useMoneyOverview();
  const {
    expenses,
    error: expensesError,
    isLoading: expensesLoading,
    isLoadingMore,
    hasMore,
    loadMore,
    mutate: reloadExpenses,
  } = useExpenses();
  const [overlay, setOverlay] = useState<MoneyOverlay>(null);

  const people = overview?.people ?? EMPTY_PEOPLE;
  const groups = overview?.groups ?? [];
  const currency = overview?.currency ?? "EUR";
  const byId = useMemo(() => new Map(people.map((p) => [p.id, p])), [people]);

  // Archived people stay in `people` so their names still resolve on old
  // expenses, but they only appear in the list while something is outstanding.
  const listed = people.filter((p) => !p.archived || p.balanceCents !== 0);

  function newExpense(personIds: string[] = [], groupId: string | null = null) {
    setOverlay({ type: "expense", expense: null, personIds, groupId });
  }

  function editExpense(expense: ExpenseDTO) {
    setOverlay({ type: "expense", expense, personIds: [], groupId: null });
  }

  return (
    <AppPage>
      <AppPageHeader
        title="Money"
        actions={
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="icon-sm"
              onClick={() => setOverlay({ type: "groups" })}
              aria-label="Groups"
            >
              <Users className="h-4.5 w-4.5" />
            </Button>
            <Button
              size="icon-sm"
              onClick={() => newExpense()}
              aria-label="New expense"
            >
              <Plus className="h-4.5 w-4.5" />
            </Button>
          </div>
        }
      />

      {/* the headline: what is out there */}
      <div className="mt-4 rounded-2xl border border-border bg-surface">
        <div className="grid grid-cols-2 divide-x divide-border">
          <div className="px-4 py-4">
            <p className="text-xs font-medium uppercase tracking-wide text-faint">
              Owed to you
            </p>
            <p className="mt-1 text-2xl font-semibold tabular-nums text-emerald-500">
              {formatMoney(overview?.owedToYouCents ?? 0, currency)}
            </p>
          </div>
          <div className="px-4 py-4">
            <p className="text-xs font-medium uppercase tracking-wide text-faint">
              You owe
            </p>
            <p
              className={cn(
                "mt-1 text-2xl font-semibold tabular-nums",
                (overview?.youOweCents ?? 0) > 0 ? "text-red-500" : "text-faint",
              )}
            >
              {formatMoney(overview?.youOweCents ?? 0, currency)}
            </p>
          </div>
        </div>

        {(overview?.coveredCents ?? 0) > 0 && (
          <div className="flex items-center gap-1.5 border-t border-border px-4 py-2.5 text-xs text-muted">
            <Gift className="h-3.5 w-3.5 shrink-0 text-pink-500" />
            {formatMoney(overview?.coveredCents ?? 0, currency)} covered as treats —
            tracked, never charged.
          </div>
        )}
      </div>

      {/* one tap to a bill with the usual suspects already on it */}
      {(groups.length > 0 || listed.length > 0) && (
        <div className="mt-4 flex flex-wrap gap-1.5">
          {groups.map((g) => (
            <button
              key={g.id}
              type="button"
              onClick={() => newExpense(g.memberIds, g.id)}
              className="inline-flex items-center gap-1.5 rounded-full border border-border px-2.5 py-1 text-xs font-medium text-muted transition-colors hover:bg-surface-2"
            >
              <span aria-hidden>{g.emoji || "👥"}</span>
              {g.name}
            </button>
          ))}
          {listed
            .filter((p) => !p.archived)
            .slice(0, 6)
            .map((p) => (
              <button
                key={p.id}
                type="button"
                onClick={() => newExpense([p.id])}
                className="inline-flex items-center gap-1.5 rounded-full border border-border py-1 pl-1 pr-2.5 text-xs font-medium text-muted transition-colors hover:bg-surface-2"
              >
                <Avatar
                  name={p.name}
                  color={p.color}
                  emoji={p.emoji}
                  size="sm"
                  className="h-5 w-5 text-[10px]"
                />
                {p.name}
              </button>
            ))}
        </div>
      )}

      {/* who owes what */}
      <div className="mt-6">
        {isLoading && people.length === 0 ? (
          <div className="flex flex-col gap-2">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-16 animate-pulse rounded-2xl bg-surface-2" />
            ))}
          </div>
        ) : listed.length === 0 ? (
          <EmptyState
            icon={<Wallet className="h-6 w-6" />}
            title="Nothing owed yet"
            description="Log the next bill you pick up — people get added as you go."
            actionLabel={
              <>
                <Plus className="h-4 w-4" />
                Add expense
              </>
            }
            onAction={() => newExpense()}
          />
        ) : (
          <ul className="flex flex-col gap-1.5">
            {listed.map((person) => (
              <li key={person.id}>
                <PersonRow
                  person={person}
                  currency={currency}
                  onOpen={() => setOverlay({ type: "person", personId: person.id })}
                />
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* every bill, loaded a page at a time as the user reaches the end */}
      {(expenses.length > 0 || expensesLoading || expensesError) && (
        <div className="mt-7">
          <p className="text-xs font-medium uppercase tracking-wide text-faint">
            Expenses
          </p>
          {expensesLoading && expenses.length === 0 ? (
            <div className="mt-2 flex flex-col gap-2">
              {[0, 1, 2].map((i) => (
                <div key={i} className="h-14 animate-pulse rounded-xl bg-surface-2" />
              ))}
            </div>
          ) : expensesError && expenses.length === 0 ? (
            <div className="mt-2 rounded-xl border border-border px-4 py-5 text-center">
              <p className="text-sm text-muted">Couldn&rsquo;t load expenses.</p>
              <button
                type="button"
                onClick={() => void reloadExpenses()}
                className="mt-2 text-sm font-medium text-primary hover:underline"
              >
                Try again
              </button>
            </div>
          ) : (
            <>
              <ul className="mt-1 divide-y divide-border">
                {expenses.map((expense) => (
                  <li key={expense.id}>
                    <ExpenseRow
                      expense={expense}
                      currency={currency}
                      nameOf={(id) => byId.get(id)?.name ?? "someone"}
                      onOpen={() => editExpense(expense)}
                    />
                  </li>
                ))}
              </ul>
              <InfiniteListFooter
                hasMore={hasMore}
                isLoading={isLoadingMore}
                onLoadMore={loadMore}
                label="Load more expenses"
              />
              {expensesError && expenses.length > 0 && (
                <div className="py-3 text-center">
                  <p className="text-xs text-muted">More expenses couldn&rsquo;t load.</p>
                  <button
                    type="button"
                    onClick={() => void reloadExpenses()}
                    className="mt-1 text-xs font-medium text-primary hover:underline"
                  >
                    Try again
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {overlay?.type === "expense" && (
        <ExpenseSheet
          open
          onClose={() => setOverlay(null)}
          people={people}
          groups={groups}
          currency={currency}
          expense={overlay.expense}
          presetPersonIds={overlay.personIds}
          presetGroupId={overlay.groupId}
        />
      )}

      {overlay?.type === "person" && (
        <PersonSheet
          key={overlay.personId}
          personId={overlay.personId}
          onClose={() => setOverlay(null)}
          currency={currency}
          onAddExpense={(id) => newExpense([id])}
          onEditExpense={editExpense}
        />
      )}

      {overlay?.type === "groups" && (
        <GroupsSheet
          open
          onClose={() => setOverlay(null)}
          groups={groups}
          people={people}
        />
      )}
    </AppPage>
  );
}

function PersonRow({
  person,
  currency,
  onOpen,
}: {
  person: PersonBalanceDTO;
  currency: string;
  onOpen: () => void;
}) {
  const settled = person.balanceCents === 0;

  return (
    <button
      type="button"
      onClick={onOpen}
      className="flex w-full items-center gap-3 rounded-2xl border border-border bg-surface px-3.5 py-3 text-left transition-colors hover:bg-surface-2"
    >
      <Avatar
        name={person.name}
        color={person.color}
        emoji={person.emoji}
        size="lg"
        className="h-10 w-10 text-sm"
      />
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">{person.name}</p>
        <p className="truncate text-xs text-faint">
          {settled
            ? person.lastActivity
              ? `Settled up · ${formatDayLabel(person.lastActivity)}`
              : "Nothing yet"
            : balanceLabel(person.balanceCents, person.name)}
          {person.coveredCents > 0 &&
            ` · ${formatMoney(person.coveredCents, currency, { compact: true })} covered`}
        </p>
      </div>
      <span
        className={cn(
          "shrink-0 text-base font-semibold tabular-nums",
          person.balanceCents > 0 && "text-emerald-500",
          person.balanceCents < 0 && "text-red-500",
          settled && "text-faint",
        )}
      >
        {settled
          ? "—"
          : formatMoney(Math.abs(person.balanceCents), currency, { compact: true })}
      </span>
    </button>
  );
}

function ExpenseRow({
  expense,
  currency,
  nameOf,
  onOpen,
}: {
  expense: ExpenseDTO;
  currency: string;
  nameOf: (id: string) => string;
  onOpen: () => void;
}) {
  // What this bill did to the user's balances: everything they fronted for
  // other people, or — when someone else paid — their own slice, owed out.
  const delta =
    expense.paidByPersonId === null
      ? expense.shares.reduce((sum, s) => sum + (s.gifted ? 0 : s.amountCents), 0)
      : -expense.myShareCents;

  const gifted = expense.shares.some((s) => s.gifted);
  const names = expense.shares.map((s) => nameOf(s.personId)).join(", ");

  return (
    <button
      type="button"
      onClick={onOpen}
      className="flex w-full items-center gap-3 py-2.5 text-left"
    >
      <span className="w-12 shrink-0 text-xs tabular-nums text-faint">
        {formatDayLabel(expense.date)}
      </span>
      <div className="min-w-0 flex-1">
        <p className="flex items-center gap-1.5 truncate text-sm font-medium">
          {gifted && <Gift className="h-3.5 w-3.5 shrink-0 text-pink-500" />}
          {expense.description || "Expense"}
        </p>
        <p className="truncate text-xs text-faint">
          {formatMoney(expense.amountCents, currency, { compact: true })}
          {names && ` · with ${names}`}
          {expense.paidByPersonId !== null &&
            ` · ${nameOf(expense.paidByPersonId)} paid`}
        </p>
      </div>
      <span
        className={cn(
          "shrink-0 text-sm font-semibold tabular-nums",
          delta > 0 && "text-emerald-500",
          delta < 0 && "text-red-500",
          delta === 0 && "text-faint",
        )}
      >
        {delta === 0
          ? "—"
          : formatMoney(delta, currency, { signed: true, compact: true })}
      </span>
    </button>
  );
}
