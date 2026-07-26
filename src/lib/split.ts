// Splitting a bill. The rules here run on both sides of the wire: the editor
// uses them to preview a split live, and the API re-runs them on save so the
// stored shares can never disagree with what was shown.
//
// One invariant holds everywhere: the shares of the other participants plus the
// user's own share add up to the bill, exactly, in cents.

import type { SplitMode } from "@/lib/types";

/** 100% in basis points. */
export const FULL_BP = 10000;

/**
 * Divide `total` across `weights` so the parts sum to exactly `total`.
 * Largest-remainder: every part is floored, then the leftover cents go to the
 * biggest fractions first, earliest index winning a tie.
 */
export function allocate(total: number, weights: number[]): number[] {
  const n = weights.length;
  if (n === 0) return [];

  const sign = total < 0 ? -1 : 1;
  const amount = Math.abs(Math.round(total));

  const safe = weights.map((w) => (Number.isFinite(w) && w > 0 ? w : 0));
  const weightSum = safe.reduce((a, b) => a + b, 0);
  if (weightSum <= 0) return new Array<number>(n).fill(0);

  const exact = safe.map((w) => (amount * w) / weightSum);
  const parts = exact.map((v) => Math.floor(v));
  let leftover = amount - parts.reduce((a, b) => a + b, 0);

  const byFraction = exact
    .map((v, i) => ({ i, frac: v - Math.floor(v) }))
    .sort((a, b) => b.frac - a.frac || a.i - b.i);

  for (let k = 0; leftover > 0; k++, leftover--) {
    parts[byFraction[k % n].i] += 1;
  }

  return sign === -1 ? parts.map((p) => -p) : parts;
}

export interface SplitParticipant {
  personId: string;
  /** PERCENT mode: the share of the bill this person carries, in basis points. */
  percentBp?: number | null;
  /** AMOUNT mode: the exact cents this person carries. */
  amountCents?: number | null;
  /** Covered as a treat — still recorded against the person, never a debt. */
  gifted?: boolean;
}

export interface SplitShare {
  personId: string;
  amountCents: number;
  percentBp: number | null;
  gifted: boolean;
}

export interface SplitResult {
  shares: SplitShare[];
  /** The user's own slice — always the part of the bill nobody else carries. */
  myShareCents: number;
  /** True when the other participants were given more than the whole bill. */
  overAssigned: boolean;
}

/**
 * Resolve a split into exact per-person cents.
 *
 * - EQUAL   — everyone carries the same, the user included unless `includeMe`
 *             is false (they paid but weren't part of it).
 * - PERCENT — each participant carries the percentage entered for them; the
 *             user carries whatever is left. "She pays 40%" means exactly that.
 * - AMOUNT  — each participant carries the amount entered for them; again the
 *             user carries the rest.
 */
export function computeSplit({
  amountCents,
  mode,
  includeMe = true,
  participants,
}: {
  amountCents: number;
  mode: SplitMode;
  includeMe?: boolean;
  participants: SplitParticipant[];
}): SplitResult {
  const total = Math.max(0, Math.round(amountCents));
  const gifted = (p: SplitParticipant) => p.gifted === true;

  // Nobody else on the bill: it is entirely the user's.
  if (participants.length === 0) {
    return { shares: [], myShareCents: total, overAssigned: false };
  }

  if (mode === "EQUAL") {
    // The user sits first so that, on an uneven cent, they absorb it.
    const weights = includeMe
      ? new Array<number>(participants.length + 1).fill(1)
      : [0, ...new Array<number>(participants.length).fill(1)];
    const parts = allocate(total, weights);

    return {
      myShareCents: parts[0],
      shares: participants.map((p, i) => ({
        personId: p.personId,
        amountCents: parts[i + 1],
        percentBp: derivePercentBp(parts[i + 1], total),
        gifted: gifted(p),
      })),
      overAssigned: false,
    };
  }

  if (mode === "PERCENT") {
    const bps = participants.map((p) => clampBp(p.percentBp));
    const assignedBp = bps.reduce((a, b) => a + b, 0);
    const overAssigned = assignedBp > FULL_BP;

    // The user's percentage is the remainder, so the weights always total 100%
    // and the allocation stays exact.
    const myBp = Math.max(0, FULL_BP - assignedBp);
    const parts = allocate(total, [myBp, ...bps]);

    return {
      myShareCents: parts[0],
      shares: participants.map((p, i) => ({
        personId: p.personId,
        amountCents: parts[i + 1],
        percentBp: bps[i],
        gifted: gifted(p),
      })),
      overAssigned,
    };
  }

  // AMOUNT
  const amounts = participants.map((p) =>
    Math.max(0, Math.round(p.amountCents ?? 0)),
  );
  const assigned = amounts.reduce((a, b) => a + b, 0);

  return {
    myShareCents: Math.max(0, total - assigned),
    shares: participants.map((p, i) => ({
      personId: p.personId,
      amountCents: amounts[i],
      percentBp: derivePercentBp(amounts[i], total),
      gifted: gifted(p),
    })),
    overAssigned: assigned > total,
  };
}

function clampBp(bp: number | null | undefined): number {
  if (bp == null || !Number.isFinite(bp)) return 0;
  return Math.min(FULL_BP, Math.max(0, Math.round(bp)));
}

function derivePercentBp(part: number, total: number): number | null {
  if (total <= 0) return null;
  return Math.round((part * FULL_BP) / total);
}

/**
 * The split to open the editor with for a freshly picked set of people.
 *
 * People with a `defaultPercent` take their usual cut; everyone else — and the
 * user — divides what is left equally. So an ordinary night out lands on a
 * plain even split, while the flatmate who always takes 30% and the sibling the
 * user always covers at 100% come out right without touching anything.
 */
export function defaultSplitFor(
  people: { id: string; defaultPercent: number | null }[],
): { mode: SplitMode; includeMe: boolean; participants: SplitParticipant[] } {
  const participants = people.map((p) => ({ personId: p.id }));

  if (people.length === 0 || people.every((p) => p.defaultPercent == null)) {
    return { mode: "EQUAL", includeMe: true, participants };
  }

  const fixedBp = people.reduce(
    (sum, p) => sum + (p.defaultPercent == null ? 0 : clampBp(p.defaultPercent * 100)),
    0,
  );
  const flexible = people.filter((p) => p.defaultPercent == null);
  const remaining = Math.max(0, FULL_BP - fixedBp);
  // The user takes one of the flexible slots, and the odd basis point with it.
  const each = flexible.length > 0 ? Math.floor(remaining / (flexible.length + 1)) : 0;

  return {
    mode: "PERCENT",
    includeMe: true,
    participants: people.map((p) => ({
      personId: p.id,
      percentBp: p.defaultPercent == null ? each : clampBp(p.defaultPercent * 100),
    })),
  };
}
