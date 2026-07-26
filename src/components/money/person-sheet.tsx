"use client";

import {
  ArrowLeft,
  Gift,
  HandCoins,
  Pencil,
  Plus,
  Trash2,
} from "lucide-react";
import { useState } from "react";
import { Avatar } from "@/components/money/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import {
  createSettlement,
  deleteSettlement,
  removePerson,
  updatePerson,
  usePersonLedger,
} from "@/lib/client/use-money";
import { cn } from "@/lib/cn";
import {
  formatMoney,
  parseAmountToCents,
  PERSON_PALETTE,
} from "@/lib/money";
import { formatDayLabel } from "@/lib/time";
import type { LedgerItemDTO, PersonDTO } from "@/lib/types";

type Mode = "ledger" | "settle" | "edit";

/** "owes you" / "you owe" / "settled up", in the app's voice. */
export function balanceLabel(cents: number, name: string): string {
  if (cents > 0) return `${name} owes you`;
  if (cents < 0) return `You owe ${name}`;
  return "Settled up";
}

export function PersonSheet({
  personId,
  onClose,
  currency,
  onAddExpense,
}: {
  personId: string | null;
  onClose: () => void;
  currency: string;
  onAddExpense: (personId: string) => void;
}) {
  const { ledger, isLoading } = usePersonLedger(personId);
  const [mode, setMode] = useState<Mode>("ledger");

  // Every fresh person opens on their history.
  const [lastId, setLastId] = useState(personId);
  if (personId !== lastId) {
    setLastId(personId);
    setMode("ledger");
  }

  const person = ledger?.person ?? null;
  const balance = ledger?.balanceCents ?? 0;

  return (
    <Sheet
      open={personId !== null}
      onClose={onClose}
      title={
        person ? (
          <span className="flex items-center gap-2">
            {mode !== "ledger" && (
              <button
                type="button"
                onClick={() => setMode("ledger")}
                aria-label="Back"
                className="grid h-7 w-7 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
              >
                <ArrowLeft className="h-4 w-4" />
              </button>
            )}
            <Avatar
              name={person.name}
              color={person.color}
              emoji={person.emoji}
              size="sm"
            />
            {person.name}
          </span>
        ) : (
          "Person"
        )
      }
    >
      {!ledger || isLoading ? (
        <div className="flex flex-col gap-2">
          {[0, 1, 2].map((i) => (
            <div key={i} className="h-14 animate-pulse rounded-xl bg-surface-2" />
          ))}
        </div>
      ) : mode === "settle" ? (
        <SettleForm
          person={ledger.person}
          balanceCents={balance}
          currency={currency}
          onDone={() => setMode("ledger")}
        />
      ) : mode === "edit" ? (
        <PersonForm
          person={ledger.person}
          onDone={() => setMode("ledger")}
          onDeleted={onClose}
        />
      ) : (
        <div className="flex flex-col gap-5">
          {/* where things stand */}
          <div className="rounded-2xl border border-border bg-surface-2/40 px-4 py-4 text-center">
            <p className="text-xs font-medium uppercase tracking-wide text-faint">
              {balanceLabel(balance, ledger.person.name)}
            </p>
            <p
              className={cn(
                "mt-1 text-3xl font-semibold tabular-nums",
                balance > 0 && "text-emerald-500",
                balance < 0 && "text-red-500",
              )}
            >
              {formatMoney(Math.abs(balance), currency)}
            </p>
            {ledger.coveredCents > 0 && (
              <p className="mt-2 inline-flex items-center gap-1.5 text-xs text-muted">
                <Gift className="h-3.5 w-3.5 text-pink-500" />
                You&rsquo;ve covered {formatMoney(ledger.coveredCents, currency)} for
                them
                {ledger.coveredThisYearCents > 0 &&
                  ledger.coveredThisYearCents !== ledger.coveredCents &&
                  ` · ${formatMoney(ledger.coveredThisYearCents, currency)} this year`}
              </p>
            )}
          </div>

          <div className="flex flex-wrap gap-2">
            <Button
              size="sm"
              variant="secondary"
              onClick={() => onAddExpense(ledger.person.id)}
            >
              <Plus className="h-3.5 w-3.5" />
              Expense
            </Button>
            <Button
              size="sm"
              variant="secondary"
              onClick={() => setMode("settle")}
              disabled={balance === 0}
            >
              <HandCoins className="h-3.5 w-3.5" />
              Settle up
            </Button>
            <Button size="sm" variant="ghost" onClick={() => setMode("edit")}>
              <Pencil className="h-3.5 w-3.5" />
              Edit
            </Button>
          </div>

          <div className="flex flex-col gap-1">
            <p className="text-xs font-medium uppercase tracking-wide text-faint">
              History
            </p>
            {ledger.items.length === 0 ? (
              <p className="py-6 text-center text-sm text-faint">
                Nothing between you two yet.
              </p>
            ) : (
              <ul className="divide-y divide-border">
                {ledger.items.map((item) => (
                  <LedgerRow
                    key={`${item.kind}-${item.id}`}
                    item={item}
                    currency={currency}
                  />
                ))}
              </ul>
            )}
          </div>
        </div>
      )}
    </Sheet>
  );
}

function LedgerRow({
  item,
  currency,
}: {
  item: LedgerItemDTO;
  currency: string;
}) {
  const [busy, setBusy] = useState(false);

  const subtitle = item.gifted
    ? `Your treat · their share of ${formatMoney(item.amountCents ?? 0, currency, { compact: true })}`
    : item.kind === "settlement"
      ? item.direction === "TO_ME"
        ? "They paid you"
        : "You paid them"
      : item.paidByPersonId
        ? `They paid ${formatMoney(item.amountCents ?? 0, currency, { compact: true })} · your share`
        : `Their share of ${formatMoney(item.amountCents ?? 0, currency, { compact: true })}`;

  async function undo() {
    setBusy(true);
    try {
      await deleteSettlement(item.id);
    } finally {
      setBusy(false);
    }
  }

  return (
    <li className="flex items-center gap-3 py-2.5">
      <span className="w-12 shrink-0 text-xs tabular-nums text-faint">
        {formatDayLabel(item.date)}
      </span>
      <div className="min-w-0 flex-1">
        <p className="flex items-center gap-1.5 truncate text-sm font-medium">
          {item.gifted && <Gift className="h-3.5 w-3.5 shrink-0 text-pink-500" />}
          {item.title}
        </p>
        <p className="truncate text-xs text-faint">{subtitle}</p>
      </div>
      <span
        className={cn(
          "shrink-0 text-sm font-semibold tabular-nums",
          item.deltaCents > 0 && "text-emerald-500",
          item.deltaCents < 0 && "text-red-500",
          item.deltaCents === 0 && "text-faint",
        )}
      >
        {item.deltaCents === 0
          ? formatMoney(item.shareCents, currency, { compact: true })
          : formatMoney(item.deltaCents, currency, { signed: true, compact: true })}
      </span>
      {item.kind === "settlement" && (
        <button
          type="button"
          onClick={undo}
          disabled={busy}
          aria-label="Undo this payback"
          className="grid h-7 w-7 shrink-0 place-items-center rounded-lg text-faint hover:bg-surface-2 hover:text-red-500"
        >
          <Trash2 className="h-3.5 w-3.5" />
        </button>
      )}
    </li>
  );
}

function SettleForm({
  person,
  balanceCents,
  currency,
  onDone,
}: {
  person: PersonDTO;
  balanceCents: number;
  currency: string;
  onDone: () => void;
}) {
  // Settling means clearing what stands, so both the direction and the amount
  // start out already correct — usually it is one tap.
  const [amountText, setAmountText] = useState(
    (Math.abs(balanceCents) / 100).toFixed(2),
  );
  const [direction, setDirection] = useState<"TO_ME" | "FROM_ME">(
    balanceCents >= 0 ? "TO_ME" : "FROM_ME",
  );
  const [dateKey, setDateKey] = useState(new Date().toISOString().slice(0, 10));
  const [notes, setNotes] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function save() {
    const amountCents = parseAmountToCents(amountText) ?? 0;
    if (amountCents <= 0) {
      setError("Enter an amount");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await createSettlement({
        personId: person.id,
        amountCents,
        direction,
        date: dateKey,
        notes: notes.trim(),
      });
      onDone();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save that");
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="inline-flex self-start rounded-full border border-border bg-surface p-0.5 text-xs font-medium">
        {(
          [
            { value: "TO_ME", label: `${person.name} paid me` },
            { value: "FROM_ME", label: `I paid ${person.name}` },
          ] as const
        ).map((o) => (
          <button
            key={o.value}
            type="button"
            onClick={() => setDirection(o.value)}
            className={cn(
              "rounded-full px-3 py-1 transition-colors",
              direction === o.value
                ? "bg-surface-2 text-foreground"
                : "text-faint hover:text-muted",
            )}
          >
            {o.label}
          </button>
        ))}
      </div>

      <label className="flex flex-col gap-1 text-xs text-faint">
        Amount
        <Input
          autoFocus
          inputMode="decimal"
          value={amountText}
          onChange={(e) => setAmountText(e.target.value)}
          className="text-lg font-semibold tabular-nums"
        />
      </label>

      <label className="flex flex-col gap-1 text-xs text-faint">
        Date
        <input
          type="date"
          value={dateKey}
          onChange={(e) => setDateKey(e.target.value)}
          className="h-11 rounded-xl border border-border bg-surface px-3.5 text-sm tabular-nums focus:outline-none focus-visible:border-primary"
        />
      </label>

      <Input
        value={notes}
        onChange={(e) => setNotes(e.target.value)}
        placeholder="Note (cash, PayPal, …)"
      />

      {error && <p className="text-sm font-medium text-red-500">{error}</p>}

      <div className="flex gap-2">
        <Button variant="secondary" className="flex-1" onClick={onDone}>
          Cancel
        </Button>
        <Button className="flex-1" onClick={save} disabled={busy}>
          Record {formatMoney(parseAmountToCents(amountText) ?? 0, currency)}
        </Button>
      </div>
    </div>
  );
}

function PersonForm({
  person,
  onDone,
  onDeleted,
}: {
  person: PersonDTO;
  onDone: () => void;
  onDeleted: () => void;
}) {
  const [name, setName] = useState(person.name);
  const [emoji, setEmoji] = useState(person.emoji ?? "");
  const [color, setColor] = useState(person.color);
  const [usesDefault, setUsesDefault] = useState(person.defaultPercent !== null);
  const [percent, setPercent] = useState(String(person.defaultPercent ?? 50));
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function save() {
    if (!name.trim()) {
      setError("Give them a name");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await updatePerson(person.id, {
        name: name.trim(),
        emoji: emoji.trim() || null,
        color,
        defaultPercent: usesDefault
          ? Math.min(100, Math.max(0, Math.round(Number(percent) || 0)))
          : null,
      });
      onDone();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save that");
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    setBusy(true);
    try {
      await removePerson(person.id);
      onDeleted();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-2">
        <Input
          value={emoji}
          onChange={(e) => setEmoji(e.target.value)}
          placeholder="🙂"
          aria-label="Emoji"
          maxLength={4}
          className="w-14 text-center"
        />
        <Input
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Name"
          aria-label="Name"
          className="flex-1"
        />
      </div>

      <div className="flex flex-wrap gap-1.5">
        {PERSON_PALETTE.map((c) => (
          <button
            key={c}
            type="button"
            aria-label={`Colour ${c}`}
            onClick={() => setColor(c)}
            style={{ backgroundColor: c }}
            className={cn(
              "h-6 w-6 rounded-full transition-transform",
              color === c
                ? "ring-2 ring-foreground ring-offset-2 ring-offset-surface"
                : "hover:scale-110",
            )}
          />
        ))}
      </div>

      <div className="rounded-xl border border-border p-3">
        <label className="flex items-start gap-2.5 text-sm">
          <input
            type="checkbox"
            checked={usesDefault}
            onChange={(e) => setUsesDefault(e.target.checked)}
            className="mt-0.5 h-4 w-4 accent-primary"
          />
          <span className="min-w-0">
            <span className="font-medium">Always takes a set share</span>
            <span className="mt-0.5 block text-xs text-faint">
              Off means they split evenly with whoever else is on the bill — right
              for most people.
            </span>
          </span>
        </label>

        {usesDefault && (
          <div className="mt-3 flex items-center gap-2 pl-6.5">
            <Input
              inputMode="numeric"
              value={percent}
              onChange={(e) => setPercent(e.target.value)}
              aria-label="Default percentage"
              className="h-9 w-20 text-right tabular-nums"
            />
            <span className="text-sm text-muted">% of every bill</span>
          </div>
        )}
      </div>

      {error && <p className="text-sm font-medium text-red-500">{error}</p>}

      <div className="flex gap-2">
        <Button
          variant="ghost"
          onClick={remove}
          disabled={busy}
          aria-label="Remove person"
          className="text-red-500 hover:bg-red-500/10 hover:text-red-500"
        >
          <Trash2 className="h-4 w-4" />
        </Button>
        <Button variant="secondary" className="flex-1" onClick={onDone}>
          Cancel
        </Button>
        <Button className="flex-1" onClick={save} disabled={busy}>
          Save
        </Button>
      </div>
    </div>
  );
}
