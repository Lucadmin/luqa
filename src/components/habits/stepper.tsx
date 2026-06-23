"use client";

import { Minus, Plus } from "lucide-react";

/** A compact −/+ stepper around a value label. */
export function Stepper({
  value,
  min = 0,
  max = Number.MAX_SAFE_INTEGER,
  step = 1,
  onChange,
  format,
  width = "w-16",
}: {
  value: number;
  min?: number;
  max?: number;
  step?: number;
  onChange: (next: number) => void;
  format?: (v: number) => string;
  width?: string;
}) {
  const clamp = (v: number) => Math.min(max, Math.max(min, v));
  return (
    <div className="inline-flex items-center gap-1.5">
      <button
        type="button"
        aria-label="Decrease"
        onClick={() => onChange(clamp(value - step))}
        disabled={value <= min}
        className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
      >
        <Minus className="h-3.5 w-3.5" />
      </button>
      <span className={`text-center text-sm font-medium tabular-nums ${width}`}>
        {format ? format(value) : value}
      </span>
      <button
        type="button"
        aria-label="Increase"
        onClick={() => onChange(clamp(value + step))}
        disabled={value >= max}
        className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
      >
        <Plus className="h-3.5 w-3.5" />
      </button>
    </div>
  );
}
