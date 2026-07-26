"use client";

import { Plus, X } from "lucide-react";
import { useEffect, useRef } from "react";
import type { GymSetDTO } from "@/lib/types";

/**
 * Weight + reps, one row per set.
 *
 * "Add set" duplicates the previous row's weight — the common case is three
 * or four sets at the same load, so re-typing it every time is pure friction.
 * Reps are left for the user to fill in, since that's the number that
 * actually changes set to set.
 */
export function SetInputList({
  sets,
  onChange,
}: {
  sets: GymSetDTO[];
  onChange: (sets: GymSetDTO[]) => void;
}) {
  const repsRefs = useRef<(HTMLInputElement | null)[]>([]);
  const focusIndex = useRef<number | null>(null);

  useEffect(() => {
    if (focusIndex.current === null) return;
    repsRefs.current[focusIndex.current]?.focus();
    focusIndex.current = null;
  }, [sets.length]);

  function patchSet(index: number, patch: Partial<GymSetDTO>) {
    onChange(sets.map((s, i) => (i === index ? { ...s, ...patch } : s)));
  }

  function removeSet(index: number) {
    onChange(sets.filter((_, i) => i !== index));
  }

  function addSet() {
    const last = sets[sets.length - 1];
    focusIndex.current = sets.length;
    onChange([...sets, { weight: last?.weight ?? null, reps: null, note: null }]);
  }

  return (
    <div className="flex flex-col gap-1">
      {sets.map((set, i) => (
        <div key={i} className="flex items-center gap-1.5">
          <span className="w-3.5 shrink-0 text-[11px] tabular-nums text-faint">
            {i + 1}
          </span>

          <NumberField
            value={set.weight}
            onChange={(v) => patchSet(i, { weight: v })}
            placeholder="kg"
            step={0.5}
            aria-label={`Weight, set ${i + 1}`}
          />

          <span className="shrink-0 text-xs text-faint">×</span>

          <NumberField
            ref={(el) => {
              repsRefs.current[i] = el;
            }}
            value={set.reps}
            onChange={(v) => patchSet(i, { reps: v })}
            placeholder="reps"
            step={1}
            aria-label={`Reps, set ${i + 1}`}
          />

          <input
            value={set.note ?? ""}
            onChange={(e) => patchSet(i, { note: e.target.value || null })}
            placeholder="L/R"
            maxLength={10}
            aria-label={`Note, set ${i + 1}`}
            className="h-8 w-11 min-w-0 rounded-lg bg-transparent px-1.5 text-xs text-muted placeholder:text-faint/50 focus:bg-surface-2 focus:outline-none"
          />

          <button
            type="button"
            onClick={() => removeSet(i)}
            aria-label={`Remove set ${i + 1}`}
            className="grid h-7 w-7 shrink-0 place-items-center rounded-lg text-faint transition-colors hover:bg-surface-2 hover:text-red-500"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      ))}

      <button
        type="button"
        onClick={addSet}
        className="mt-0.5 flex items-center gap-1 self-start rounded-lg px-1 py-1 text-xs font-medium text-primary transition-colors hover:bg-surface-2"
      >
        <Plus className="h-3.5 w-3.5" />
        Add set
      </button>
    </div>
  );
}

function NumberField({
  value,
  onChange,
  placeholder,
  step,
  ref,
  ...rest
}: {
  value: number | null;
  onChange: (value: number | null) => void;
  placeholder: string;
  step: number;
  ref?: React.Ref<HTMLInputElement>;
} & Omit<
  React.InputHTMLAttributes<HTMLInputElement>,
  "value" | "onChange" | "placeholder" | "ref" | "type" | "step"
>) {
  return (
    <input
      ref={ref}
      type="number"
      inputMode="decimal"
      step={step}
      value={value ?? ""}
      onChange={(e) => {
        const raw = e.target.value;
        onChange(raw === "" ? null : Number(raw));
      }}
      placeholder={placeholder}
      className="h-8 w-14 min-w-0 rounded-lg bg-surface-2 px-2 text-sm tabular-nums placeholder:text-faint focus:outline-none focus:ring-1 focus:ring-primary"
      {...rest}
    />
  );
}
