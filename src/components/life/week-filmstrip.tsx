"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/cn";
import { periodStripeBackground, type PeriodRange, WEEKS_PER_YEAR } from "@/lib/life";

interface WeekFilmstripProps {
  /** Age-year row currently shown. */
  year: number;
  /** Column to center on within that row. */
  focusCol: number;
  /** Bumped on every jump so the same target re-centers even if unchanged. */
  jumpToken: number;
  totalWeeks: number;
  currentWeek: number;
  cellPeriods: PeriodRange[][];
  noteWeeks: Set<number>;
  milestoneWeeks: Set<number>;
  labelFor: (weekIndex: number) => string;
  onOpenWeek: (weekIndex: number) => void;
  onPrevYear: () => void;
  onNextYear: () => void;
  onToday: () => void;
  maxYear: number;
}

// Keyed on (year, jumpToken) so every jump — including one that lands back on
// the same year — remounts this subtree fresh: roving tabindex resets to the
// new target for free, and the centering effect below runs exactly once per
// jump instead of needing to synchronize state from a prop.
export function WeekFilmstrip(props: WeekFilmstripProps) {
  return <FilmstripYear key={`${props.year}:${props.jumpToken}`} {...props} />;
}

function FilmstripYear({
  year,
  focusCol,
  totalWeeks,
  currentWeek,
  cellPeriods,
  noteWeeks,
  milestoneWeeks,
  labelFor,
  onOpenWeek,
  onPrevYear,
  onNextYear,
  onToday,
  maxYear,
}: WeekFilmstripProps) {
  const stripRef = useRef<HTMLDivElement>(null);
  const cellRefs = useRef<(HTMLButtonElement | null)[]>([]);
  const [rovingCol, setRovingCol] = useState(focusCol);

  useEffect(() => {
    const strip = stripRef.current;
    const target = cellRefs.current[focusCol];
    if (!strip || !target) return;
    const delta = target.offsetLeft + target.clientWidth / 2 - strip.clientWidth / 2;
    strip.scrollTo({ left: Math.max(0, delta), behavior: "auto" });
  }, [focusCol]);

  const startWeek = year * WEEKS_PER_YEAR;
  const cols: number[] = [];
  for (let col = 0; col < WEEKS_PER_YEAR && startWeek + col < totalWeeks; col++) cols.push(col);

  return (
    <div className="shrink-0 border-t border-border bg-surface px-3 py-2.5 md:px-5">
      <div className="mb-2 flex items-center justify-between gap-2">
        <div className="min-w-0">
          <p className="text-sm font-semibold">Age {year}</p>
          <p className="text-xs text-muted">Tap a week to review it</p>
        </div>
        <div className="flex shrink-0 items-center gap-1.5">
          <button
            type="button"
            aria-label="Previous year"
            onClick={onPrevYear}
            disabled={year <= 0}
            className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted transition-colors motion-reduce:transition-none hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onToday}
            className="h-8 rounded-lg border border-border px-2.5 text-xs font-medium text-muted transition-colors motion-reduce:transition-none hover:bg-surface-2 hover:text-foreground"
          >
            Today
          </button>
          <button
            type="button"
            aria-label="Next year"
            onClick={onNextYear}
            disabled={year >= maxYear}
            className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted transition-colors motion-reduce:transition-none hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <ChevronRight className="h-4 w-4" />
          </button>
        </div>
      </div>

      <div ref={stripRef} className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
        {cols.map((col) => {
          const i = startWeek + col;
          const periods = cellPeriods[i] ?? [];
          const bg = periodStripeBackground(periods.map((p) => p.color));
          const lived = i <= currentWeek;
          const isCurrent = i === currentWeek;
          return (
            <button
              key={i}
              ref={(el) => {
                cellRefs.current[col] = el;
              }}
              type="button"
              title={labelFor(i)}
              tabIndex={col === rovingCol ? 0 : -1}
              onFocus={() => setRovingCol(col)}
              onClick={() => onOpenWeek(i)}
              onKeyDown={(e) => {
                if (e.key === "ArrowLeft" && col > 0) {
                  e.preventDefault();
                  cellRefs.current[col - 1]?.focus();
                } else if (e.key === "ArrowRight" && col < cols.length - 1) {
                  e.preventDefault();
                  cellRefs.current[col + 1]?.focus();
                }
              }}
              style={bg ? { background: bg } : undefined}
              className={cn(
                "relative h-11 w-11 shrink-0 rounded-xl border transition-colors motion-reduce:transition-none focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
                bg
                  ? "border-transparent"
                  : lived
                    ? "border-transparent bg-foreground/30"
                    : "border-border-strong bg-surface",
                isCurrent && "outline outline-2 outline-offset-2 outline-primary",
              )}
            >
              {noteWeeks.has(i) && !isCurrent && (
                <span
                  aria-hidden
                  className="absolute inset-1 rounded-lg ring-1 ring-inset ring-foreground/60"
                />
              )}
              {milestoneWeeks.has(i) && (
                <span
                  aria-hidden
                  className="absolute left-1/2 top-1/2 h-1.5 w-1.5 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white shadow ring-1 ring-black/30"
                />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
