"use client";

import { Plus } from "lucide-react";
import { useEffect, useMemo, useRef } from "react";
import { CategoryDot } from "@/components/timeline/category-picker";
import type { Gap } from "@/lib/timeline-layout";
import { computeGaps, computeLayout } from "@/lib/timeline-layout";
import { cn } from "@/lib/cn";
import {
  formatClock,
  formatDuration,
  HOUR_HEIGHT,
  MINUTES_PER_DAY,
  PX_PER_MINUTE,
  startOfLocalDay,
} from "@/lib/time";
import type { CategoryDTO, TimeEntryDTO } from "@/lib/types";

const GUTTER = 52; // px for hour labels
const TOTAL_HEIGHT = MINUTES_PER_DAY * PX_PER_MINUTE;

export function Timeline({
  day,
  entries,
  categories,
  nowMin,
  onOpenEntry,
  onOpenGap,
}: {
  day: Date;
  entries: TimeEntryDTO[];
  categories: CategoryDTO[];
  nowMin: number | null;
  onOpenEntry: (entry: TimeEntryDTO) => void;
  onOpenGap: (gap: Gap) => void;
}) {
  const focusRef = useRef<HTMLDivElement>(null);
  const dayStartMs = startOfLocalDay(day).getTime();

  const categoryById = useMemo(() => {
    const map = new Map<string, CategoryDTO>();
    for (const c of categories) map.set(c.id, c);
    return map;
  }, [categories]);

  const layout = useMemo(
    () => computeLayout(entries, dayStartMs, nowMin),
    [entries, dayStartMs, nowMin],
  );
  const gaps = useMemo(
    () => computeGaps(entries, dayStartMs, nowMin),
    [entries, dayStartMs, nowMin],
  );

  // On mount, bring the interesting part of the day into view.
  const focusMin = nowMin ?? layout[0]?.startMin ?? 8 * 60;
  useEffect(() => {
    focusRef.current?.scrollIntoView({ block: "center" });
  }, []);

  return (
    <div className="relative">
      <div className="relative" style={{ height: TOTAL_HEIGHT }}>
        {/* scroll anchor */}
        <div
          ref={focusRef}
          className="pointer-events-none absolute"
          style={{ top: focusMin * PX_PER_MINUTE }}
        />
        {/* hour grid */}
        {Array.from({ length: 24 }).map((_, h) => (
          <div
            key={h}
            className="absolute inset-x-0 flex items-start"
            style={{ top: h * HOUR_HEIGHT, height: HOUR_HEIGHT }}
          >
            <span className="w-[52px] shrink-0 -translate-y-2 pr-2 text-right text-[11px] tabular-nums text-faint">
              {h > 0 ? `${String(h).padStart(2, "0")}:00` : ""}
            </span>
            <div className="flex-1 border-t border-grid-line" />
          </div>
        ))}

        {/* gaps */}
        {gaps.map((gap) => {
          const top = gap.startMin * PX_PER_MINUTE;
          const height = (gap.endMin - gap.startMin) * PX_PER_MINUTE;
          return (
            <button
              key={`gap-${gap.startMin}`}
              type="button"
              onClick={() => onOpenGap(gap)}
              className="group absolute flex items-center justify-center rounded-lg border border-dashed border-border text-faint transition-colors hover:border-primary/50 hover:bg-primary/5 hover:text-primary"
              style={{
                top,
                height,
                left: GUTTER,
                right: 4,
              }}
            >
              <span className="flex items-center gap-1.5 text-xs font-medium opacity-0 transition-opacity group-hover:opacity-100">
                <Plus className="h-3.5 w-3.5" />
                Fill {formatDuration(gap.endMin - gap.startMin)}
              </span>
            </button>
          );
        })}

        {/* entries */}
        {layout.map(({ entry, startMin, endMin, running, lane, lanes }) => {
          const top = startMin * PX_PER_MINUTE;
          const height = (endMin - startMin) * PX_PER_MINUTE;
          const category = entry.categoryId
            ? categoryById.get(entry.categoryId)
            : null;
          const color = category?.color ?? "#9aa0aa";
          const laneWidth = `calc((100% - ${GUTTER}px) / ${lanes})`;
          const compact = height < 34;

          return (
            <button
              key={entry.id}
              type="button"
              onClick={() => onOpenEntry(entry)}
              className={cn(
                "absolute flex flex-col overflow-hidden rounded-lg border-l-2 px-2.5 text-left transition-shadow hover:shadow-md",
                compact ? "justify-center py-0" : "py-1.5",
              )}
              style={{
                top,
                height: Math.max(height - 2, 16),
                left: `calc(${GUTTER}px + ${lane} * ${laneWidth})`,
                width: `calc(${laneWidth} - 4px)`,
                backgroundColor: `${color}1f`,
                borderLeftColor: color,
              }}
            >
              <div className="flex w-full items-center gap-1.5">
                {running && (
                  <span className="h-1.5 w-1.5 shrink-0 animate-pulse rounded-full bg-now-line" />
                )}
                <span className="truncate text-xs font-medium text-foreground">
                  {entry.description || "Untitled"}
                </span>
              </div>
              {!compact && (
                <div className="mt-0.5 flex items-center gap-1.5 text-[10px] text-muted">
                  {category && <CategoryDot color={category.color} className="h-1.5 w-1.5" />}
                  <span className="tabular-nums">
                    {formatClock(startMin)}–{running ? "now" : formatClock(endMin)}
                  </span>
                  <span className="text-faint">·</span>
                  <span>{formatDuration(endMin - startMin)}</span>
                </div>
              )}
            </button>
          );
        })}

        {/* now line */}
        {nowMin !== null && (
          <div
            className="pointer-events-none absolute inset-x-0 z-10 flex items-center"
            style={{ top: nowMin * PX_PER_MINUTE }}
          >
            <span className="ml-[46px] h-2 w-2 rounded-full bg-now-line" />
            <div className="h-px flex-1 bg-now-line" />
          </div>
        )}
      </div>
    </div>
  );
}
