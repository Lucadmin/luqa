"use client";

import { useLayoutEffect, useRef, useState } from "react";
import { cn } from "@/lib/cn";
import { WEEKS_PER_YEAR } from "@/lib/life";

const GUTTER = 30; // px reserved for age labels down the left edge

interface LifeGridProps {
  totalWeeks: number;
  currentWeek: number;
  /** Per-cell band colour, or null. Length === totalWeeks. */
  cellColors: (string | null)[];
  noteWeeks: Set<number>;
  milestoneWeeks: Set<number>;
  /** Cell size multiplier over the fit-to-width size. 1 = fit. */
  zoom: number;
  selectedWeek: number | null;
  onSelect: (weekIndex: number) => void;
  labelFor: (weekIndex: number) => string;
}

/** Measure an element's content width, reactively. */
function useWidth<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const [width, setWidth] = useState(0);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const update = () => setWidth(el.clientWidth);
    update();
    const ro = new ResizeObserver(update);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  return [ref, width] as const;
}

export function LifeGrid({
  totalWeeks,
  currentWeek,
  cellColors,
  noteWeeks,
  milestoneWeeks,
  zoom,
  selectedWeek,
  onSelect,
  labelFor,
}: LifeGridProps) {
  const [ref, width] = useWidth<HTMLDivElement>();

  const years = Math.ceil(totalWeeks / WEEKS_PER_YEAR);
  const basePitch = width ? Math.max(5, Math.floor((width - GUTTER) / WEEKS_PER_YEAR)) : 10;
  const pitch = Math.round(basePitch * zoom);
  const gap = Math.max(1, Math.round(pitch * 0.14));
  const cell = Math.max(3, pitch - gap);
  const radius = Math.max(1, Math.round(cell * 0.22));

  return (
    <div ref={ref} className="h-full w-full overflow-auto">
      <div
        className="grid w-max"
        style={{
          gridTemplateColumns: `${GUTTER}px repeat(${WEEKS_PER_YEAR}, ${cell}px)`,
          gridAutoRows: `${cell}px`,
          gap: `${gap}px`,
        }}
      >
        {Array.from({ length: years }, (_, row) => {
          const showLabel = row % 10 === 0;
          return (
            <div key={`r${row}`} style={{ display: "contents" }}>
              <div
                className="flex items-center justify-end pr-1 text-[10px] leading-none text-faint tabular-nums"
                style={{ height: cell }}
              >
                {showLabel ? row : ""}
              </div>
              {Array.from({ length: WEEKS_PER_YEAR }, (_, col) => {
                const i = row * WEEKS_PER_YEAR + col;
                if (i >= totalWeeks) return <div key={i} />;
                const lived = i <= currentWeek;
                const fill = cellColors[i];
                const isCurrent = i === currentWeek;
                const isSelected = i === selectedWeek;
                const hasNote = noteWeeks.has(i);
                const isMilestone = milestoneWeeks.has(i);
                return (
                  <button
                    key={i}
                    type="button"
                    title={labelFor(i)}
                    onClick={() => onSelect(i)}
                    style={{
                      width: cell,
                      height: cell,
                      borderRadius: radius,
                      backgroundColor: fill ?? undefined,
                    }}
                    className={cn(
                      "relative transition-colors",
                      !fill && (lived ? "bg-foreground/25" : "bg-transparent"),
                      !lived && "border border-border/60",
                      hasNote && !isCurrent && "ring-1 ring-inset ring-foreground/70",
                      isCurrent && "z-10 ring-2 ring-primary",
                      isSelected && "z-20 outline outline-2 outline-offset-1 outline-primary",
                      "hover:brightness-110",
                    )}
                  >
                    {isMilestone && cell >= 7 && (
                      <span
                        aria-hidden
                        className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white shadow ring-1 ring-black/30"
                        style={{ width: Math.max(3, cell * 0.42), height: Math.max(3, cell * 0.42) }}
                      />
                    )}
                  </button>
                );
              })}
            </div>
          );
        })}
      </div>
    </div>
  );
}
