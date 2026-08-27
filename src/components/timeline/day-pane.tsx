"use client";

import { Moon, Plus } from "lucide-react";
import { useCallback, useMemo, useRef, useState } from "react";
import { CategoryDot } from "@/components/timeline/category-picker";
import { DraftBlock } from "@/components/timeline/draft-block";
import type { InlineDraft } from "@/components/timeline/types";
import { cn } from "@/lib/cn";
import {
  addDays,
  DAY_HEIGHT,
  formatClock,
  formatDuration,
  HOUR_HEIGHT,
  MINUTES_PER_DAY,
  PX_PER_MINUTE,
  snapMinutes,
  startOfLocalDay,
} from "@/lib/time";
import { computeGaps, computeLayout } from "@/lib/timeline-layout";
import type { CategoryDTO, SleepEntryDTO, TimeEntryDTO } from "@/lib/types";

const GUTTER = 52; // px for hour labels
const DEFAULT_LEN = 30; // minutes — default size for a tap/click-created block
const MIN_DRAG = 10; // minutes — shorter drags fall back to the default size

const SOURCE_LABELS: Record<SleepEntryDTO["source"], string> = {
  HEALTH_CONNECT: "Health Connect",
  APPLE_HEALTH: "Apple Health",
  GOOGLE_HEALTH: "Google Health",
  MANUAL: "Manual",
};

function sleepMinutesFor(entry: SleepEntryDTO): number {
  if (entry.sleepMinutes !== null) return entry.sleepMinutes;
  const duration = (Date.parse(entry.endTime) - Date.parse(entry.startTime)) / 60000;
  return Math.max(0, duration - (entry.awakeMinutes ?? 0));
}

/**
 * One calendar day, midnight→midnight, absolutely positioned inside the
 * continuous timeline. Anything crossing midnight is clipped here and picked
 * up by the neighbouring pane, so the two halves read as a single block.
 */
export function DayPane({
  day,
  offsetY,
  dayStartHour,
  entries,
  sleepEntries,
  categories,
  nowMs,
  inlineDraft,
  onOpenEntry,
  onOpenSleep,
  onCreateInline,
  onChangeInlineRange,
  onChangeInlineDescription,
  onApplyInlineSuggestion,
  onSaveInline,
  onExpandInline,
  onCancelInline,
  saving,
}: {
  day: Date;
  /** Absolute y of this day inside the timeline's virtual scroll space. */
  offsetY: number;
  dayStartHour: number;
  entries: TimeEntryDTO[];
  sleepEntries: SleepEntryDTO[];
  categories: CategoryDTO[];
  nowMs: number;
  inlineDraft: InlineDraft | null;
  onOpenEntry: (entry: TimeEntryDTO) => void;
  onOpenSleep: (entry: SleepEntryDTO) => void;
  onCreateInline: (day: Date, startMin: number, endMin: number, autoFocus: boolean) => void;
  onChangeInlineRange: (startMin: number, endMin: number) => void;
  onChangeInlineDescription: (value: string) => void;
  onApplyInlineSuggestion: (description: string, categoryId: string | null) => void;
  onSaveInline: () => void;
  onExpandInline: () => void;
  onCancelInline: () => void;
  saving: boolean;
}) {
  const containerRef = useRef<HTMLDivElement>(null);
  const dayStartMs = startOfLocalDay(day).getTime();
  const dayEndMs = startOfLocalDay(addDays(day, 1)).getTime();

  // Minutes since this pane's midnight. Outside [0, 1440] on every day but the
  // current one — which is exactly what the layout helpers want for clamping
  // still-running entries.
  const nowMin = (nowMs - dayStartMs) / 60000;
  const isToday = nowMin >= 0 && nowMin <= MINUTES_PER_DAY;

  // Drag-to-create bookkeeping (mouse) / tap-to-create (touch).
  const createRef = useRef<{
    pointerId: number;
    type: string;
    anchorMin: number;
    startClientY: number;
    engaged: boolean;
  } | null>(null);
  const [preview, setPreview] = useState<{ startMin: number; endMin: number } | null>(
    null,
  );

  const categoryById = useMemo(() => {
    const map = new Map<string, CategoryDTO>();
    for (const c of categories) map.set(c.id, c);
    return map;
  }, [categories]);

  const layout = useMemo(
    () => computeLayout(entries, dayStartMs, nowMin, 0),
    [entries, dayStartMs, nowMin],
  );
  const sleepLayout = useMemo(
    () =>
      sleepEntries
        .map((entry) => {
          const rawStartMin = (Date.parse(entry.startTime) - dayStartMs) / 60000;
          const rawEndMin = (Date.parse(entry.endTime) - dayStartMs) / 60000;
          const startMin = Math.max(0, Math.min(MINUTES_PER_DAY, rawStartMin));
          const endMin = Math.max(0, Math.min(MINUTES_PER_DAY, rawEndMin));
          if (endMin <= 0 || startMin >= MINUTES_PER_DAY || endMin <= startMin) {
            return null;
          }
          return { entry, startMin, endMin, rawStartMin, rawEndMin };
        })
        .filter((item): item is {
          entry: SleepEntryDTO;
          startMin: number;
          endMin: number;
          rawStartMin: number;
          rawEndMin: number;
        } => item !== null),
    [sleepEntries, dayStartMs],
  );
  const gaps = useMemo(
    // Past days have no "now" to trail off to; future days have no gaps at all.
    () => computeGaps(entries, dayStartMs, isToday ? nowMin : null),
    [entries, dayStartMs, isToday, nowMin],
  );

  const clientYToMin = useCallback((clientY: number) => {
    const el = containerRef.current;
    if (!el) return 0;
    const rect = el.getBoundingClientRect();
    const raw = (clientY - rect.top) / PX_PER_MINUTE;
    return Math.max(0, Math.min(MINUTES_PER_DAY, raw));
  }, []);

  function onPointerDown(e: React.PointerEvent) {
    // Let entries, gap pills and the draft block handle their own pointers.
    if ((e.target as HTMLElement).closest("[data-entry],[data-sleep],[data-fill],[data-draft]")) {
      return;
    }
    if (e.pointerType === "mouse" && e.button !== 0) return;

    createRef.current = {
      pointerId: e.pointerId,
      type: e.pointerType,
      anchorMin: clientYToMin(e.clientY),
      startClientY: e.clientY,
      engaged: false,
    };

    // Mouse: capture so a drag draws a box. Touch: stay passive so a vertical
    // swipe still scrolls the timeline; only a stationary tap creates.
    if (e.pointerType === "mouse") {
      e.preventDefault();
      containerRef.current?.setPointerCapture(e.pointerId);
    }
  }

  function onPointerMove(e: React.PointerEvent) {
    const st = createRef.current;
    if (!st || st.pointerId !== e.pointerId) return;

    if (st.type === "mouse") {
      if (!st.engaged && Math.abs(e.clientY - st.startClientY) > 3) {
        st.engaged = true;
      }
      if (st.engaged) {
        const cur = snapMinutes(clientYToMin(e.clientY));
        const anchor = snapMinutes(st.anchorMin);
        setPreview({
          startMin: Math.min(anchor, cur),
          endMin: Math.max(anchor, cur),
        });
      }
    } else if (Math.abs(e.clientY - st.startClientY) > 8) {
      // Treated as a scroll — bail out of create.
      createRef.current = null;
    }
  }

  function onPointerUp(e: React.PointerEvent) {
    const st = createRef.current;
    if (!st || st.pointerId !== e.pointerId) return;
    createRef.current = null;
    setPreview(null);

    const cur = snapMinutes(clientYToMin(e.clientY));
    const anchor = snapMinutes(st.anchorMin);

    let start: number;
    let end: number;
    if (st.engaged && st.type === "mouse" && Math.abs(cur - anchor) >= MIN_DRAG) {
      start = Math.min(anchor, cur);
      end = Math.max(anchor, cur);
    } else {
      start = anchor;
      end = anchor + DEFAULT_LEN;
    }
    if (end > MINUTES_PER_DAY) {
      end = MINUTES_PER_DAY;
      start = Math.max(0, end - DEFAULT_LEN);
    }
    onCreateInline(day, start, end, st.type === "mouse");
  }

  function onPointerCancel() {
    createRef.current = null;
    setPreview(null);
  }

  return (
    <div
      ref={containerRef}
      className="absolute inset-x-0 select-none"
      style={{ top: offsetY, height: DAY_HEIGHT }}
      onPointerDown={onPointerDown}
      onPointerMove={onPointerMove}
      onPointerUp={onPointerUp}
      onPointerCancel={onPointerCancel}
    >
      {/* day boundary + date marker in the gutter */}
      <div className="pointer-events-none absolute inset-x-0 top-0 border-t border-border-strong" />
      <div
        className={cn(
          "pointer-events-none absolute left-0 top-1 w-[52px] pr-2 text-right leading-tight",
          isToday ? "text-primary" : "text-muted",
        )}
      >
        <div className="text-[11px] font-semibold">
          {day.toLocaleDateString(undefined, { weekday: "short" })}
        </div>
        <div className="text-[10px] text-faint">
          {day.toLocaleDateString(undefined, { month: "short", day: "numeric" })}
        </div>
      </div>

      {/* hour grid — 01:00 … 23:00 (00:00 is the day boundary above). Hours
          before the day-start cutoff are drawn faintly: the clock says today,
          but they still count towards yesterday. */}
      {Array.from({ length: 23 }).map((_, i) => {
        const h = i + 1;
        const preCutoff = h < dayStartHour;
        return (
          <div
            key={h}
            className="pointer-events-none absolute inset-x-0 flex items-start"
            style={{ top: h * HOUR_HEIGHT, height: HOUR_HEIGHT }}
          >
            <span
              className={cn(
                "w-[52px] shrink-0 -translate-y-2 pr-2 text-right text-[11px] tabular-nums",
                preCutoff ? "text-faint/40" : "text-faint",
              )}
            >
              {String(h).padStart(2, "0")}:00
            </span>
            <div
              className={cn(
                "flex-1 border-t",
                preCutoff ? "border-dashed border-grid-line/30" : "border-grid-line",
              )}
            />
          </div>
        );
      })}

      {/* gaps — dashed hint with a small "fill whole gap" pill */}
      {gaps.map((gap) => {
        const top = gap.startMin * PX_PER_MINUTE;
        const height = (gap.endMin - gap.startMin) * PX_PER_MINUTE;
        const showPill = gap.endMin - gap.startMin >= 15;
        return (
          <div
            key={`gap-${gap.startMin}`}
            className="pointer-events-none absolute rounded-lg border border-dashed border-border/70"
            style={{ top, height, left: GUTTER, right: 4 }}
          >
            {showPill && (
              <button
                data-fill
                type="button"
                onClick={() => onCreateInline(day, gap.startMin, gap.endMin, true)}
                className="pointer-events-auto absolute left-1/2 top-1/2 inline-flex -translate-x-1/2 -translate-y-1/2 items-center gap-1.5 rounded-full border border-border bg-surface px-3 py-1 text-xs font-medium text-muted shadow-sm transition-colors hover:border-primary/50 hover:text-primary"
              >
                <Plus className="h-3.5 w-3.5" />
                Fill {formatDuration(gap.endMin - gap.startMin)}
              </button>
            )}
          </div>
        );
      })}

      {/* sleep sessions — read-only health data, not tracked time */}
      {sleepLayout.map(({ entry, startMin, endMin, rawStartMin, rawEndMin }) => {
        const top = startMin * PX_PER_MINUTE;
        const clippedTop = rawStartMin < 0;
        const clippedBottom = rawEndMin > MINUTES_PER_DAY;
        const height = (endMin - startMin) * PX_PER_MINUTE;
        const compact = height < 38;
        const asleep = sleepMinutesFor(entry);
        const source = entry.sourceApp ?? SOURCE_LABELS[entry.source];

        return (
          <button
            key={entry.id}
            data-sleep
            type="button"
            onClick={() => onOpenSleep(entry)}
            className={cn(
              "absolute z-[1] flex overflow-hidden rounded-lg border border-indigo-300/40 bg-indigo-500/[0.08] px-2.5 text-left text-indigo-950 shadow-sm dark:border-indigo-400/20 dark:bg-indigo-400/[0.10] dark:text-indigo-100",
              "transition-shadow hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
              compact ? "items-center" : "flex-col justify-center py-1.5",
              clippedTop && "rounded-t-none border-t-0",
              clippedBottom && "rounded-b-none border-b-0",
            )}
            style={{
              top,
              height: Math.max(height - (clippedBottom ? 0 : 2), 18),
              left: GUTTER,
              right: 4,
            }}
            title={`${formatClock(rawStartMin)}-${formatClock(rawEndMin)} · ${formatDuration(asleep)} sleep`}
          >
            <div className="flex min-w-0 items-center gap-1.5">
              <Moon className="h-3.5 w-3.5 shrink-0 text-indigo-500 dark:text-indigo-300" />
              <span className="truncate text-xs font-medium">Sleep</span>
              <span className="shrink-0 text-[10px] tabular-nums text-indigo-700/80 dark:text-indigo-200/80">
                {formatDuration(asleep)}
              </span>
            </div>
            {!compact && (
              <div className="mt-0.5 flex min-w-0 items-center gap-1.5 text-[10px] text-indigo-700/70 dark:text-indigo-200/70">
                <span className="tabular-nums">
                  {formatClock(rawStartMin)}-{formatClock(rawEndMin)}
                </span>
                <span className="text-indigo-700/40 dark:text-indigo-200/40">·</span>
                <span className="truncate">{source}</span>
              </div>
            )}
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
        const clippedTop = Date.parse(entry.startTime) < dayStartMs;
        const clippedBottom =
          (entry.endTime ? Date.parse(entry.endTime) : nowMs) > dayEndMs;

        return (
          <button
            key={entry.id}
            data-entry
            type="button"
            onClick={() => onOpenEntry(entry)}
            className={cn(
              "absolute flex flex-col overflow-hidden rounded-lg border-l-2 px-2.5 text-left transition-shadow hover:shadow-md",
              compact ? "justify-center py-0" : "py-1.5",
              clippedTop && "rounded-t-none",
              clippedBottom && "rounded-b-none",
            )}
            style={{
              top,
              height: Math.max(height - (clippedBottom ? 0 : 2), 16),
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

      {/* drag-create preview (mouse) */}
      {preview && !inlineDraft && (
        <div
          className="pointer-events-none absolute z-20 rounded-lg border-2 border-dashed border-primary bg-primary/10"
          style={{
            top: preview.startMin * PX_PER_MINUTE,
            height: Math.max((preview.endMin - preview.startMin) * PX_PER_MINUTE, 2),
            left: GUTTER,
            right: 4,
          }}
        >
          <span className="block px-2 py-1 text-[11px] font-semibold tabular-nums text-primary">
            {formatClock(preview.startMin)}–{formatClock(preview.endMin)}
          </span>
        </div>
      )}

      {/* in-place draft block */}
      {inlineDraft && (
        <DraftBlock
          startMin={inlineDraft.startMin}
          endMin={inlineDraft.endMin}
          description={inlineDraft.description}
          categoryId={inlineDraft.categoryId}
          categories={categories}
          autoFocus={inlineDraft.autoFocus}
          maxEndMin={MINUTES_PER_DAY}
          clientYToMin={clientYToMin}
          onChangeRange={onChangeInlineRange}
          onChangeDescription={onChangeInlineDescription}
          onApplySuggestion={onApplyInlineSuggestion}
          onSave={onSaveInline}
          onExpand={onExpandInline}
          onCancel={onCancelInline}
          saving={saving}
        />
      )}

      {/* now line */}
      {isToday && (
        <div
          className="pointer-events-none absolute inset-x-0 z-10 flex items-center"
          style={{ top: nowMin * PX_PER_MINUTE }}
        >
          <span className="ml-[46px] h-2 w-2 rounded-full bg-now-line" />
          <div className="h-px flex-1 bg-now-line" />
        </div>
      )}
    </div>
  );
}
