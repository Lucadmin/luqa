"use client";

import { Check, Gift, Plus, Trash2 } from "lucide-react";
import { useMemo, useState } from "react";
import { Avatar } from "@/components/money/avatar";
import {
  previewSplit,
  SplitEditor,
  type SplitRow,
  type SplitState,
} from "@/components/money/split-editor";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import {
  createExpense,
  createPerson,
  deleteExpense,
  updateExpense,
} from "@/lib/client/use-money";
import { cn } from "@/lib/cn";
import { currencySymbol, formatMoney, parseAmountToCents } from "@/lib/money";
import { defaultSplitFor } from "@/lib/split";
import type { ExpenseDTO, PersonDTO, PersonGroupDTO } from "@/lib/types";

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function defaultsFor(
  peopleById: Map<string, PersonDTO>,
  ids: string[],
  keepGifts: SplitRow[] = [],
): SplitState {
  const gifted = new Set(
    keepGifts.filter((row) => row.gifted).map((row) => row.personId),
  );
  const selected = ids
    .map((id) => peopleById.get(id))
    .filter((person): person is PersonDTO => Boolean(person));
  const defaults = defaultSplitFor(
    selected.map((person) => ({
      id: person.id,
      defaultPercent: person.defaultPercent,
    })),
  );

  return {
    mode: defaults.mode,
    includeMe: defaults.includeMe,
    rows: defaults.participants.map((participant) => ({
      personId: participant.personId,
      percentBp: participant.percentBp ?? null,
      amountCents: null,
      gifted: gifted.has(participant.personId),
    })),
  };
}

/**
 * Log a bill. The default path is three taps — amount, who, save — and every
 * refinement (who paid, the exact split, a treat) sits one level down without
 * getting in the way of the fast case.
 */
export function ExpenseSheet({
  open,
  onClose,
  people,
  groups,
  currency,
  expense = null,
  presetPersonIds = [],
  presetGroupId = null,
}: {
  open: boolean;
  onClose: () => void;
  people: PersonDTO[];
  groups: PersonGroupDTO[];
  currency: string;
  expense?: ExpenseDTO | null;
  presetPersonIds?: string[];
  presetGroupId?: string | null;
}) {
  const peopleById = useMemo(
    () => new Map(people.map((person) => [person.id, person])),
    [people],
  );

  const [amountText, setAmountText] = useState(() =>
    expense ? (expense.amountCents / 100).toFixed(2) : "",
  );
  const [description, setDescription] = useState(expense?.description ?? "");
  const [dateKey, setDateKey] = useState(expense?.date ?? todayKey());
  const [paidBy, setPaidBy] = useState<string | null>(
    expense?.paidByPersonId ?? null,
  );
  const [groupId, setGroupId] = useState<string | null>(
    expense?.groupId ?? presetGroupId,
  );
  const [split, setSplit] = useState<SplitState>(() =>
    expense
      ? {
          mode: expense.splitMode,
          includeMe: expense.myShareCents > 0,
          rows: expense.shares.map((share) => ({
            personId: share.personId,
            percentBp: share.percentBp,
            amountCents: share.amountCents,
            gifted: share.gifted,
          })),
        }
      : defaultsFor(peopleById, presetPersonIds),
  );
  const [customized, setCustomized] = useState(Boolean(expense));
  const [showSplit, setShowSplit] = useState(Boolean(expense));
  const [newName, setNewName] = useState("");
  const [addingPerson, setAddingPerson] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const selectedIds = split.rows.map((r) => r.personId);
  const amountCents = Math.max(0, parseAmountToCents(amountText) ?? 0);
  const preview = previewSplit(split, amountCents);
  const canGift = paidBy === null;
  const allGifted = split.rows.length > 0 && split.rows.every((r) => r.gifted);

  // Normally you pick the payer from whoever is on the bill — plus, on an older
  // expense, whoever paid it even if they aren't in the split any more.
  const payerOptions = [
    ...selectedIds,
    ...(paidBy && !selectedIds.includes(paidBy) ? [paidBy] : []),
  ]
    .map((id) => peopleById.get(id))
    .filter((p): p is PersonDTO => Boolean(p));

  function setSelection(ids: string[]) {
    if (customized) {
      // Keep what the user has already tuned; new faces start at nothing.
      const existing = new Map(split.rows.map((r) => [r.personId, r]));
      setSplit({
        ...split,
        rows: ids.map(
          (id) =>
            existing.get(id) ?? {
              personId: id,
              percentBp: 0,
              amountCents: 0,
              gifted: false,
            },
        ),
      });
    } else {
      setSplit(defaultsFor(peopleById, ids, split.rows));
    }
  }

  function togglePerson(id: string) {
    setSelection(
      selectedIds.includes(id)
        ? selectedIds.filter((x) => x !== id)
        : [...selectedIds, id],
    );
    // Dropping the payer out of the split would leave a stale payer behind.
    if (paidBy === id && selectedIds.includes(id)) setPaidBy(null);
  }

  function toggleGroup(group: PersonGroupDTO) {
    if (groupId === group.id) {
      setGroupId(null);
      setSelection(selectedIds.filter((id) => !group.memberIds.includes(id)));
      return;
    }
    setGroupId(group.id);
    setSelection([...new Set([...selectedIds, ...group.memberIds])]);
  }

  function toggleTreatAll() {
    const next = !allGifted;
    setSplit({ ...split, rows: split.rows.map((r) => ({ ...r, gifted: next })) });
  }

  async function addPerson() {
    const name = newName.trim();
    if (!name) return;
    setBusy(true);
    setError(null);
    try {
      const person = await createPerson({ name });
      setAddingPerson(false);
      setNewName("");
      const nextIds = [...selectedIds, person.id];
      if (customized) {
        setSplit((current) => ({
          ...current,
          rows: [
            ...current.rows,
            {
              personId: person.id,
              percentBp: 0,
              amountCents: 0,
              gifted: false,
            },
          ],
        }));
      } else {
        const withPerson = new Map(peopleById).set(person.id, person);
        setSplit(defaultsFor(withPerson, nextIds, split.rows));
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not add that person");
    } finally {
      setBusy(false);
    }
  }

  async function save() {
    if (amountCents <= 0) {
      setError("Enter an amount");
      return;
    }
    if (split.rows.length === 0) {
      setError("Pick who this was with");
      return;
    }
    if (preview.overAssigned) {
      setError(
        split.mode === "PERCENT"
          ? "The shares add up to more than 100%"
          : "The shares add up to more than the total",
      );
      return;
    }

    setBusy(true);
    setError(null);
    try {
      const payload = {
        description: description.trim(),
        amountCents,
        date: dateKey,
        paidByPersonId: paidBy,
        groupId,
        splitMode: split.mode,
        includeMe: split.includeMe,
        participants: split.rows.map((r) => ({
          personId: r.personId,
          percentBp: r.percentBp,
          amountCents: r.amountCents,
          gifted: r.gifted,
        })),
      };
      if (expense) await updateExpense(expense.id, payload);
      else await createExpense(payload);
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save that");
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!expense) return;
    setBusy(true);
    try {
      await deleteExpense(expense.id);
      onClose();
    } finally {
      setBusy(false);
    }
  }

  const summary = [
    `You ${formatMoney(preview.myShareCents, currency, { compact: true })}`,
    ...preview.shares.map((s) => {
      const person = peopleById.get(s.personId);
      const money = formatMoney(s.amountCents, currency, { compact: true });
      return `${person?.name ?? "?"} ${money}${s.gifted ? " (treat)" : ""}`;
    }),
  ].join(" · ");

  return (
    <Sheet
      open={open}
      onClose={onClose}
      title={expense ? "Edit expense" : "New expense"}
      footer={
        <div className="flex items-center gap-2">
          {expense && (
            <Button
              variant="ghost"
              size="md"
              onClick={remove}
              disabled={busy}
              aria-label="Delete expense"
              className="text-red-500 hover:bg-red-500/10 hover:text-red-500"
            >
              <Trash2 className="h-4 w-4" />
            </Button>
          )}
          <Button className="flex-1" onClick={save} disabled={busy}>
            {expense ? "Save changes" : "Add expense"}
          </Button>
        </div>
      }
    >
      <div className="flex flex-col gap-5">
        {/* amount + what for */}
        <div className="flex flex-col gap-2">
          <div className="flex items-baseline gap-2 border-b border-border pb-2">
            <span className="text-2xl font-semibold text-faint">
              {currencySymbol(currency)}
            </span>
            <input
              autoFocus
              inputMode="decimal"
              aria-label="Amount"
              placeholder="0.00"
              value={amountText}
              onChange={(e) => setAmountText(e.target.value)}
              className="w-full min-w-0 bg-transparent text-3xl font-semibold tabular-nums placeholder:text-faint/50 focus:outline-none"
            />
          </div>
          <Input
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            placeholder="What for? (dinner, tickets, …)"
          />
        </div>

        {/* who was in on it */}
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium uppercase tracking-wide text-faint">With</p>

          {groups.length > 0 && (
            <div className="flex flex-wrap gap-1.5">
              {groups.map((g) => (
                <button
                  key={g.id}
                  type="button"
                  onClick={() => toggleGroup(g)}
                  className={cn(
                    "inline-flex items-center gap-1.5 rounded-full border px-2.5 py-1 text-xs font-medium transition-colors",
                    groupId === g.id
                      ? "border-primary bg-primary/10 text-primary"
                      : "border-border text-muted hover:bg-surface-2",
                  )}
                >
                  <span aria-hidden>{g.emoji || "👥"}</span>
                  {g.name}
                </button>
              ))}
            </div>
          )}

          <div className="flex flex-wrap gap-1.5">
            {people
              .filter((p) => !p.archived || selectedIds.includes(p.id))
              .map((p) => {
                const on = selectedIds.includes(p.id);
                return (
                  <button
                    key={p.id}
                    type="button"
                    onClick={() => togglePerson(p.id)}
                    aria-pressed={on}
                    className={cn(
                      "inline-flex items-center gap-1.5 rounded-full border py-1 pl-1 pr-2.5 text-xs font-medium transition-colors",
                      on
                        ? "border-transparent text-foreground"
                        : "border-border text-muted hover:bg-surface-2",
                    )}
                    style={on ? { backgroundColor: `${p.color}22` } : undefined}
                  >
                    <Avatar
                      name={p.name}
                      color={p.color}
                      emoji={p.emoji}
                      size="sm"
                      className="h-5 w-5 text-[10px]"
                    />
                    {p.name}
                    {on && <Check className="h-3 w-3" />}
                  </button>
                );
              })}

            {addingPerson ? (
              <span className="inline-flex items-center gap-1">
                <Input
                  autoFocus
                  value={newName}
                  onChange={(e) => setNewName(e.target.value)}
                  onKeyDown={(e) => {
                    if (e.key === "Enter") {
                      e.preventDefault();
                      void addPerson();
                    }
                    if (e.key === "Escape") setAddingPerson(false);
                  }}
                  placeholder="Name"
                  className="h-7 w-28 rounded-full px-3 text-xs"
                />
                <Button size="sm" onClick={addPerson} disabled={busy || !newName.trim()}>
                  Add
                </Button>
              </span>
            ) : (
              <button
                type="button"
                onClick={() => setAddingPerson(true)}
                className="inline-flex items-center gap-1 rounded-full border border-dashed border-border px-2.5 py-1 text-xs font-medium text-faint hover:text-muted"
              >
                <Plus className="h-3 w-3" />
                New
              </button>
            )}
          </div>
        </div>

        {/* the split, folded away until it is needed */}
        {split.rows.length > 0 && (
          <div className="flex flex-col gap-2">
            <div className="flex items-center justify-between gap-2">
              <p className="text-xs font-medium uppercase tracking-wide text-faint">
                Split
              </p>
              <button
                type="button"
                onClick={() => setShowSplit((v) => !v)}
                className="text-xs font-medium text-primary hover:underline"
              >
                {showSplit ? "Done" : "Adjust"}
              </button>
            </div>

            {showSplit ? (
              <SplitEditor
                state={split}
                onChange={(next) => {
                  setCustomized(true);
                  setSplit(next);
                }}
                people={people}
                amountCents={amountCents}
                currency={currency}
                canGift={canGift}
                onRemove={(id) => togglePerson(id)}
              />
            ) : (
              <p className="text-sm text-muted">{summary}</p>
            )}

            {canGift && (
              <button
                type="button"
                onClick={toggleTreatAll}
                aria-pressed={allGifted}
                className={cn(
                  "inline-flex w-fit items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-colors",
                  allGifted
                    ? "border-transparent bg-pink-500/15 text-pink-500"
                    : "border-border text-muted hover:bg-surface-2",
                )}
              >
                <Gift className="h-3.5 w-3.5" />
                {allGifted ? "My treat — nobody owes this" : "My treat"}
              </button>
            )}
          </div>
        )}

        {/* the rest: who paid, when */}
        <div className="grid grid-cols-2 gap-3">
          <label className="flex flex-col gap-1 text-xs text-faint">
            Paid by
            <select
              value={paidBy ?? ""}
              onChange={(e) => setPaidBy(e.target.value || null)}
              className="h-9 rounded-lg border border-border bg-surface px-2 text-sm focus:outline-none focus-visible:border-primary"
            >
              <option value="">You</option>
              {payerOptions.map((person) => (
                <option key={person.id} value={person.id}>
                  {person.name}
                </option>
              ))}
            </select>
          </label>

          <label className="flex flex-col gap-1 text-xs text-faint">
            Date
            <input
              type="date"
              value={dateKey}
              onChange={(e) => setDateKey(e.target.value || todayKey())}
              className="h-9 rounded-lg border border-border bg-surface px-2 text-sm tabular-nums focus:outline-none focus-visible:border-primary"
            />
          </label>
        </div>

        {paidBy !== null && (
          <p className="-mt-2 text-xs text-faint">
            They fronted this one, so only your own share moves your balance with
            them.
          </p>
        )}

        {error && <p className="text-sm font-medium text-red-500">{error}</p>}
      </div>
    </Sheet>
  );
}
