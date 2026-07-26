"use client";

import { Gift, X } from "lucide-react";
import { useState } from "react";
import { Avatar } from "@/components/money/avatar";
import { cn } from "@/lib/cn";
import {
  currencySymbol,
  formatMoney,
  formatPercent,
  parseAmountToCents,
  parsePercentToBp,
} from "@/lib/money";
import { computeSplit, FULL_BP, type SplitShare } from "@/lib/split";
import type { PersonDTO, SplitMode } from "@/lib/types";

export interface SplitRow {
  personId: string;
  /** PERCENT mode: what this person carries, in basis points. */
  percentBp: number | null;
  /** AMOUNT mode: what this person carries, in cents. */
  amountCents: number | null;
  gifted: boolean;
}

export interface SplitState {
  mode: SplitMode;
  /** EQUAL only: whether the user is one of the equal parts. */
  includeMe: boolean;
  rows: SplitRow[];
}

const MODES: { value: SplitMode; label: string }[] = [
  { value: "EQUAL", label: "Equally" },
  { value: "PERCENT", label: "Percent" },
  { value: "AMOUNT", label: "Amounts" },
];

/** Run the split for a draft expense — the same maths the server will apply. */
export function previewSplit(state: SplitState, amountCents: number) {
  return computeSplit({
    amountCents,
    mode: state.mode,
    includeMe: state.includeMe,
    participants: state.rows.map((r) => ({
      personId: r.personId,
      percentBp: r.percentBp,
      amountCents: r.amountCents,
      gifted: r.gifted,
    })),
  });
}

export function SplitEditor({
  state,
  onChange,
  people,
  amountCents,
  currency,
  canGift,
  onRemove,
}: {
  state: SplitState;
  onChange: (next: SplitState) => void;
  people: PersonDTO[];
  amountCents: number;
  currency: string;
  /** Treats only make sense on a bill the user paid. */
  canGift: boolean;
  onRemove: (personId: string) => void;
}) {
  // Half-typed values ("33." or "") live here so they don't get normalised away
  // mid-keystroke; the parsed number goes straight to `state`.
  const [drafts, setDrafts] = useState<Record<string, string>>({});

  const split = previewSplit(state, amountCents);
  const byPerson = new Map<string, SplitShare>(
    split.shares.map((s) => [s.personId, s]),
  );
  const nameOf = new Map(people.map((p) => [p.id, p]));

  function setRow(personId: string, patch: Partial<SplitRow>) {
    onChange({
      ...state,
      rows: state.rows.map((r) => (r.personId === personId ? { ...r, ...patch } : r)),
    });
  }

  const giftedTotal = split.shares.reduce(
    (sum, s) => sum + (s.gifted ? s.amountCents : 0),
    0,
  );

  return (
    <div className="flex flex-col gap-3">
      {/* how to divide it */}
      <div className="inline-flex self-start rounded-full border border-border bg-surface p-0.5 text-xs font-medium">
        {MODES.map((m) => (
          <button
            key={m.value}
            type="button"
            onClick={() => onChange({ ...state, mode: m.value })}
            className={cn(
              "rounded-full px-3 py-1 transition-colors",
              state.mode === m.value
                ? "bg-surface-2 text-foreground"
                : "text-faint hover:text-muted",
            )}
          >
            {m.label}
          </button>
        ))}
      </div>

      <div className="divide-y divide-border rounded-xl border border-border bg-surface-2/40">
        {/* the user's own slice — always whatever nobody else carries */}
        <div className="flex items-center gap-3 px-3 py-2.5">
          <span className="grid h-9 w-9 shrink-0 place-items-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
            You
          </span>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-medium">Your share</p>
            {state.mode === "EQUAL" && (
              <button
                type="button"
                onClick={() => onChange({ ...state, includeMe: !state.includeMe })}
                className="mt-0.5 text-xs text-faint underline-offset-2 hover:text-muted hover:underline"
              >
                {state.includeMe ? "Included in the split" : "Not part of this"}
              </button>
            )}
          </div>
          <span className="shrink-0 text-sm font-semibold tabular-nums">
            {formatMoney(split.myShareCents, currency)}
          </span>
        </div>

        {state.rows.map((row) => {
          const person = nameOf.get(row.personId);
          if (!person) return null;
          const share = byPerson.get(row.personId);
          const cents = share?.amountCents ?? 0;

          return (
            <div key={row.personId} className="flex items-center gap-2.5 px-3 py-2.5">
              <Avatar name={person.name} color={person.color} emoji={person.emoji} />

              <div className="min-w-0 flex-1">
                <p
                  className={cn(
                    "truncate text-sm font-medium",
                    row.gifted && "text-muted",
                  )}
                >
                  {person.name}
                </p>
                <p className="mt-0.5 text-xs text-faint">
                  {row.gifted
                    ? "Your treat — not a debt"
                    : share?.percentBp != null
                      ? formatPercent(share.percentBp)
                      : "—"}
                </p>
              </div>

              {state.mode === "PERCENT" && (
                <div className="flex h-8 w-[4.5rem] shrink-0 items-center rounded-lg border border-border bg-surface pr-2">
                  <input
                    inputMode="decimal"
                    aria-label={`${person.name}'s percentage`}
                    value={
                      drafts[row.personId] ??
                      (row.percentBp == null ? "" : String(row.percentBp / 100))
                    }
                    onChange={(e) => {
                      setDrafts((d) => ({ ...d, [row.personId]: e.target.value }));
                      setRow(row.personId, {
                        percentBp: Math.min(
                          FULL_BP,
                          Math.max(0, parsePercentToBp(e.target.value) ?? 0),
                        ),
                      });
                    }}
                    onBlur={() =>
                      setDrafts((d) => {
                        const next = { ...d };
                        delete next[row.personId];
                        return next;
                      })
                    }
                    className="w-full min-w-0 bg-transparent px-2 text-right text-sm tabular-nums focus:outline-none"
                  />
                  <span className="text-xs text-faint">%</span>
                </div>
              )}

              {state.mode === "AMOUNT" && (
                <div className="flex h-8 w-24 shrink-0 items-center rounded-lg border border-border bg-surface pl-2">
                  <span className="text-xs text-faint">{currencySymbol(currency)}</span>
                  <input
                    inputMode="decimal"
                    aria-label={`${person.name}'s amount`}
                    value={
                      drafts[row.personId] ??
                      (row.amountCents == null ? "" : (row.amountCents / 100).toFixed(2))
                    }
                    onChange={(e) => {
                      setDrafts((d) => ({ ...d, [row.personId]: e.target.value }));
                      setRow(row.personId, {
                        amountCents: Math.max(0, parseAmountToCents(e.target.value) ?? 0),
                      });
                    }}
                    onBlur={() =>
                      setDrafts((d) => {
                        const next = { ...d };
                        delete next[row.personId];
                        return next;
                      })
                    }
                    className="w-full min-w-0 bg-transparent px-1.5 text-right text-sm tabular-nums focus:outline-none"
                  />
                </div>
              )}

              {state.mode === "EQUAL" && (
                <span
                  className={cn(
                    "shrink-0 text-sm font-semibold tabular-nums",
                    row.gifted && "text-muted line-through decoration-1",
                  )}
                >
                  {formatMoney(cents, currency)}
                </span>
              )}

              {canGift && (
                <button
                  type="button"
                  aria-label={
                    row.gifted
                      ? `Stop covering ${person.name}'s share`
                      : `Cover ${person.name}'s share as a treat`
                  }
                  aria-pressed={row.gifted}
                  title="My treat — track it, don't charge it"
                  onClick={() => setRow(row.personId, { gifted: !row.gifted })}
                  className={cn(
                    "grid h-8 w-8 shrink-0 place-items-center rounded-lg transition-colors",
                    row.gifted
                      ? "bg-pink-500/15 text-pink-500"
                      : "text-faint hover:bg-surface-2 hover:text-muted",
                  )}
                >
                  <Gift className="h-4 w-4" />
                </button>
              )}

              <button
                type="button"
                aria-label={`Remove ${person.name}`}
                onClick={() => onRemove(row.personId)}
                className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-faint hover:bg-surface-2 hover:text-foreground"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            </div>
          );
        })}
      </div>

      {split.overAssigned && (
        <p className="text-xs font-medium text-red-500">
          {state.mode === "PERCENT"
            ? "The shares add up to more than 100%."
            : "The shares add up to more than the total."}
        </p>
      )}

      {giftedTotal > 0 && !split.overAssigned && (
        <p className="text-xs text-muted">
          {formatMoney(giftedTotal, currency)} of this is your treat — tracked, but
          nobody owes it.
        </p>
      )}
    </div>
  );
}
