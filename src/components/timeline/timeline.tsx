"use client";

import { Plus } from "lucide-react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { CategoryDot } from "@/components/timeline/category-picker";
import { DraftBlock } from "@/components/timeline/draft-block";
import type { InlineDraft } from "@/components/timeline/types";
import { computeGaps, computeLayout } from "@/lib/timeline-layout";
import { cn } from "@/lib/cn";
import {
  clampToDay,
  DAY_START_HOUR,
  formatClock,
  formatDuration,
  HOUR_HEIGHT,
  MINUTES_PER_DAY,
  PX_PER_MINUTE,
  snapMinutes,
  startOfLocalDay,
} from "@/lib/time";
import type { CategoryDTO, TimeEntryDTO } from "@/lib/types";

const GUTTER = 52; // px for hour labels
const DEFAULT_LEN = 30; // minutes — default size for a tap/click-created block
const MIN_DRAG = 10; // minutes — shorter drags fall back to the default size

export function Timeline({
  day,
  entries,
  categories,
  nowMin,
  inlineDraft,
  dayStartHour = DAY_START_HOUR,
  onOpenEntry,
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
  entries: TimeEntryDTO[];
  categories: CategoryDTO[];
  nowMin: number | null;
  inlineDraft: InlineDraft | null;
  dayStartHour?: number;
  onOpenEntry: (entry: TimeEntryDTO) => void;
  onCreateInline: (startMin: number, endMin: number, autoFocus: boolean) => void;
  onChangeInlineRange: (startMin: number, endMin: number) => void;
  onChangeInlineDescription: (value: string) => void;
  onApplyInlineSuggestion: (description: string, categoryId: string | null) => void;
  onSaveInline: () => void;
  onExpandInline: () => void;
  onCancelInline: () => void;
  saving: boolean;
}) {
  const focusRef = useRef<HTMLDivElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const dayStartMs = startOfLocalDay(day).getTime();

  // The grid runs midnight→midnight plus an "overflow" tail so entries that
  // run into the early hours (and still count to this day) stay visible.
  const overflowHours = Math.max(1, dayStartHour);
  const overflowMin = overflowHours * 60;
  const totalHeight = (MINUTES_PER_DAY + overflowMin) * PX_PER_MINUTE;

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
    () => computeLayout(entries, dayStartMs, nowMin, overflowMin),
    [entries, dayStartMs, nowMin, overflowMin],
  );
  const gaps = useMemo(
    () => computeGaps(entries, dayStartMs, nowMin),
    [entries, dayStartMs, nowMin],
  );

  const clientYToMin = useCallback((clientY: number) => {
    const el = containerRef.current;
    if (!el) return 0;
    const rect = el.getBoundingClientRect();
    return clampToDay((clientY - rect.top) / PX_PER_MINUTE);
  }, []);

  // On mount, bring the interesting part of the day into view.
  const focusMin = nowMin ?? layout[0]?.startMin ?? 8 * 60;
  useEffect(() => {
    focusRef.current?.scrollIntoView({ block: "center" });
  }, []);

  function onPointerDown(e: React.PointerEvent) {
    // Let entries, gap pills and the draft block handle their own pointers.
    if ((e.target as HTMLElement).closest("[data-entry],[data-fill],[data-draft]")) {
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
    onCreateInline(start, end, st.type === "mouse");
  }

  function onPointerCancel() {
    createRef.current = null;
    setPreview(null);
  }

  return (
    <div className="relative">
      <div
        ref={containerRef}
        className="relative select-none"
        style={{ height: totalHeight }}
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={onPointerCancel}
      >
        {/* scroll anchor */}
        <div
          ref={focusRef}
          className="pointer-events-none absolute"
          style={{ top: focusMin * PX_PER_MINUTE }}
        />
        {/* hour grid — 24 normal hours + overflow zone past midnight */}
        {Array.from({ length: 24 + overflowHours }).map((_, h) => {
          const past = h >= 24;
          const label = h === 0 ? "" : `${String(h % 24).padStart(2, "0")}:00`;
          return (
            <div
              key={h}
              className="pointer-events-none absolute inset-x-0 flex items-start"
              style={{ top: h * HOUR_HEIGHT, height: HOUR_HEIGHT }}
            >
              <span
                className={`w-[52px] shrink-0 -translate-y-2 pr-2 text-right text-[11px] tabular-nums ${past ? "text-faint/40" : "text-faint"}`}
              >
                {label}
              </span>
              <div
                className={`flex-1 border-t ${past ? "border-dashed border-grid-line/30" : "border-grid-line"}`}
              />
            </div>
          );
        })}

        {/* midnight divider — bold line with "next day" label */}
        <div
          className="pointer-events-none absolute inset-x-0 flex items-center"
          style={{ top: MINUTES_PER_DAY * PX_PER_MINUTE }}
        >
          <span className="w-[52px] shrink-0 -translate-y-2.5 pr-2 text-right text-[10px] text-faint/50">
            00:00
          </span>
          <div className="flex-1 border-t-2 border-border/50" />
        </div>

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
                  onClick={() => onCreateInline(gap.startMin, gap.endMin, true)}
                  className="pointer-events-auto absolute left-1/2 top-1/2 inline-flex -translate-x-1/2 -translate-y-1/2 items-center gap-1.5 rounded-full border border-border bg-surface px-3 py-1 text-xs font-medium text-muted shadow-sm transition-colors hover:border-primary/50 hover:text-primary"
                >
                  <Plus className="h-3.5 w-3.5" />
                  Fill {formatDuration(gap.endMin - gap.startMin)}
                </button>
              )}
            </div>
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
              data-entry
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
