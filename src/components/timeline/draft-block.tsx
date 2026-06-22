"use client";

import { Check, Settings2, X } from "lucide-react";
import { useRef, useState } from "react";
import { CategoryDot } from "@/components/timeline/category-picker";
import { useClickOutside } from "@/lib/client/use-click-outside";
import { useSuggestions } from "@/lib/client/use-suggestions";
import { cn } from "@/lib/cn";
import {
  clampToDay,
  formatClock,
  formatDuration,
  MINUTES_PER_DAY,
  PX_PER_MINUTE,
  SNAP_MINUTES,
  snapMinutes,
} from "@/lib/time";
import type { CategoryDTO } from "@/lib/types";

const GUTTER = 52; // keep in sync with timeline.tsx
const TOOLBAR_H = 52;

type DragMode = "start" | "end" | "move";

/**
 * An in-place draft entry rendered directly on the timeline. The ends can be
 * dragged to resize and the body dragged to move; a floating toolbar carries a
 * quick title plus a hand-off to the full editor popup.
 */
export function DraftBlock({
  startMin,
  endMin,
  description,
  categoryId,
  categories,
  autoFocus,
  clientYToMin,
  onChangeRange,
  onChangeDescription,
  onApplySuggestion,
  onSave,
  onExpand,
  onCancel,
  saving,
}: {
  startMin: number;
  endMin: number;
  description: string;
  categoryId: string | null;
  categories: CategoryDTO[];
  autoFocus: boolean;
  clientYToMin: (clientY: number) => number;
  onChangeRange: (start: number, end: number) => void;
  onChangeDescription: (value: string) => void;
  onApplySuggestion: (description: string, categoryId: string | null) => void;
  onSave: () => void;
  onExpand: () => void;
  onCancel: () => void;
  saving: boolean;
}) {
  const drag = useRef<{ mode: DragMode | null; grabOffset: number }>({
    mode: null,
    grabOffset: 0,
  });

  const [focused, setFocused] = useState(false);
  const toolbarRef = useRef<HTMLDivElement>(null);
  useClickOutside(toolbarRef, () => setFocused(false), focused);
  const { suggestions } = useSuggestions(description);
  const selectedCategory = categoryId
    ? (categories.find((c) => c.id === categoryId) ?? null)
    : null;

  const top = startMin * PX_PER_MINUTE;
  const height = Math.max((endMin - startMin) * PX_PER_MINUTE, 18);

  function startDrag(mode: DragMode, e: React.PointerEvent) {
    e.preventDefault();
    e.stopPropagation();
    e.currentTarget.setPointerCapture(e.pointerId);
    drag.current.mode = mode;
    if (mode === "move") {
      drag.current.grabOffset = clientYToMin(e.clientY) - startMin;
    }
  }

  function onBodyDown(e: React.PointerEvent) {
    startDrag("move", e);
  }
  function onStartDown(e: React.PointerEvent) {
    startDrag("start", e);
  }
  function onEndDown(e: React.PointerEvent) {
    startDrag("end", e);
  }

  function onMove(e: React.PointerEvent) {
    const mode = drag.current.mode;
    if (!mode) return;
    const cur = snapMinutes(clientYToMin(e.clientY));
    if (mode === "start") {
      onChangeRange(clampToDay(Math.min(cur, endMin - SNAP_MINUTES)), endMin);
    } else if (mode === "end") {
      onChangeRange(startMin, clampToDay(Math.max(cur, startMin + SNAP_MINUTES)));
    } else {
      const dur = endMin - startMin;
      const s = Math.max(
        0,
        Math.min(MINUTES_PER_DAY - dur, snapMinutes(cur - drag.current.grabOffset)),
      );
      onChangeRange(s, s + dur);
    }
  }

  function endDrag() {
    drag.current.mode = null;
  }

  // Anchor the toolbar below the block, flipping above it near the day's end.
  const nearBottom = endMin > MINUTES_PER_DAY - 200;
  const aboveTop = top - TOOLBAR_H - 8;
  const toolbarTop = nearBottom && aboveTop > 4 ? aboveTop : top + height + 8;

  return (
    <div data-draft>
      {/* selection rectangle */}
      <div
        className="absolute z-20 touch-none rounded-lg border-2 border-primary bg-primary/15 shadow-sm"
        style={{ top, height, left: GUTTER, right: 4 }}
        onPointerDown={onBodyDown}
        onPointerMove={onMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
      >
        <span className="pointer-events-none block px-2 py-1 text-[11px] font-semibold tabular-nums text-primary">
          {formatClock(startMin)}–{formatClock(endMin)} ·{" "}
          {formatDuration(endMin - startMin)}
        </span>

        {/* top resize handle */}
        <div
          className="absolute inset-x-0 -top-2.5 flex h-5 cursor-ns-resize touch-none items-center justify-center"
          onPointerDown={onStartDown}
          onPointerMove={onMove}
          onPointerUp={endDrag}
          onPointerCancel={endDrag}
        >
          <span className="h-1.5 w-10 rounded-full bg-primary shadow-sm" />
        </div>

        {/* bottom resize handle */}
        <div
          className="absolute inset-x-0 -bottom-2.5 flex h-5 cursor-ns-resize touch-none items-center justify-center"
          onPointerDown={onEndDown}
          onPointerMove={onMove}
          onPointerUp={endDrag}
          onPointerCancel={endDrag}
        >
          <span className="h-1.5 w-10 rounded-full bg-primary shadow-sm" />
        </div>
      </div>

      {/* floating toolbar */}
      <div
        ref={toolbarRef}
        className="absolute z-30 rounded-xl border border-border bg-surface p-1.5 shadow-lg"
        style={{ top: toolbarTop, left: GUTTER, right: 4 }}
      >
        <div className="flex items-center gap-1.5">
          {selectedCategory && (
            <span title={selectedCategory.name} className="pl-1.5">
              <CategoryDot color={selectedCategory.color} className="h-3 w-3" />
            </span>
          )}
          <input
            autoFocus={autoFocus}
            value={description}
            onChange={(e) => onChangeDescription(e.target.value)}
            onFocus={() => setFocused(true)}
            onKeyDown={(e) => {
              if (e.key === "Enter") onSave();
              if (e.key === "Escape") onCancel();
            }}
            placeholder="What were you doing?"
            className="min-w-0 flex-1 bg-transparent px-1 py-1 text-sm outline-none placeholder:text-faint"
          />
          <button
            type="button"
            onClick={onExpand}
            aria-label="More options"
            title="More options"
            className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
          >
            <Settings2 className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onCancel}
            aria-label="Cancel"
            title="Cancel"
            className="grid h-8 w-8 shrink-0 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
          >
            <X className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={onSave}
            disabled={saving}
            className={cn(
              "inline-flex h-8 shrink-0 items-center gap-1.5 rounded-lg bg-primary px-3 text-sm font-medium text-primary-foreground transition-opacity",
              saving && "opacity-60",
            )}
          >
            <Check className="h-4 w-4" />
            Save
          </button>
        </div>

        {/* suggestions from history (title + remembered category) */}
        {focused && suggestions.length > 0 && (
          <div className="absolute inset-x-0 top-full z-40 mt-1 overflow-hidden rounded-xl border border-border bg-surface shadow-lg">
            <div className="max-h-56 overflow-y-auto py-1">
              {suggestions.map((s, i) => {
                const cat = s.categoryId
                  ? categories.find((c) => c.id === s.categoryId)
                  : null;
                return (
                  <button
                    key={`${s.description}-${s.categoryId ?? "none"}-${i}`}
                    type="button"
                    onClick={() => {
                      onApplySuggestion(s.description, s.categoryId);
                      setFocused(false);
                    }}
                    className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm hover:bg-surface-2"
                  >
                    {cat ? (
                      <CategoryDot color={cat.color} />
                    ) : (
                      <span className="h-2.5 w-2.5" />
                    )}
                    <span className="flex-1 truncate">{s.description}</span>
                    {cat && (
                      <span className="shrink-0 text-xs text-faint">{cat.name}</span>
                    )}
                  </button>
                );
              })}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
