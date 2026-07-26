"use client";

import {
  useCallback,
  useEffect,
  useImperativeHandle,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { DayPane } from "@/components/timeline/day-pane";
import type { InlineDraft } from "@/components/timeline/types";
import {
  addDays,
  DAY_HEIGHT,
  dayNumber,
  isoDateKey,
  MINUTES_PER_DAY,
  PX_PER_MINUTE,
  startOfLocalDay,
} from "@/lib/time";
import type { CategoryDTO, SleepEntryDTO, TimeEntryDTO } from "@/lib/types";

// How far the timeline reaches in each direction. Bounded so the scroll height
// (~6M px) stays comfortably inside every browser's maximum element height.
const DAYS_BEFORE = 3650; // ~10 years
const DAYS_AFTER = 400;
const TOTAL_DAYS = DAYS_BEFORE + DAYS_AFTER + 1;
const SCROLL_HEIGHT = TOTAL_DAYS * DAY_HEIGHT;

/** Animate rather than teleport for short hops. */
const SMOOTH_LIMIT = 3 * DAY_HEIGHT;

const clampOffset = (n: number) => Math.max(0, Math.min(TOTAL_DAYS - 1, n));

export interface TimelineHandle {
  /** Move by whole days, keeping the same time-of-day in view. */
  shiftDays: (n: number) => void;
  /** Jump to a date, keeping the same time-of-day in view. */
  goToDay: (day: Date) => void;
  /** Centre the current moment. */
  goToNow: () => void;
}

/**
 * A continuous, scrollable timeline: one absolutely-positioned pane per
 * calendar day inside a single tall scroller, with only the visible days (plus
 * a pane of buffer either side) mounted. Scrolling reports the day at the top
 * of the viewport; the imperative handle scrolls back the other way.
 */
export function Timeline({
  ref,
  dayStartHour,
  nowMs,
  entries,
  sleepEntries,
  categories,
  inlineDraft,
  onDayChange,
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
  ref?: React.Ref<TimelineHandle>;
  dayStartHour: number;
  nowMs: number;
  entries: TimeEntryDTO[];
  sleepEntries: SleepEntryDTO[];
  categories: CategoryDTO[];
  inlineDraft: InlineDraft | null;
  onDayChange: (day: Date) => void;
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
  const scrollRef = useRef<HTMLDivElement>(null);
  // Pending programmatic scroll. Repeated day-steps chain off this rather than
  // off a mid-animation scrollTop, so holding the chevron doesn't lose days.
  const targetRef = useRef<number | null>(null);
  const frameRef = useRef(0);
  const reportedRef = useRef<number | null>(null);

  // Day 0 of the virtual range. Fixed for the lifetime of the view so scroll
  // offsets never shift under the user.
  const [epochDay] = useState(() =>
    addDays(startOfLocalDay(new Date()), -DAYS_BEFORE),
  );
  const offsetOf = useCallback(
    (day: Date) => dayNumber(day) - dayNumber(epochDay),
    [epochDay],
  );

  const [range, setRange] = useState(() => {
    const today = clampOffset(DAYS_BEFORE);
    return { first: today - 1, last: today + 1 };
  });

  /** Scroll position of an instant, in the virtual coordinate space. */
  const yForInstant = useCallback(
    (ms: number) => {
      const at = new Date(ms);
      const minutes = (ms - startOfLocalDay(at).getTime()) / 60000;
      return offsetOf(at) * DAY_HEIGHT + minutes * PX_PER_MINUTE;
    },
    [offsetOf],
  );

  /** The logical day (day-start cutoff applied) shown at a scroll position. */
  const logicalOffsetAt = useCallback(
    (px: number) => {
      const minutes = px / PX_PER_MINUTE;
      const offset = Math.floor(minutes / MINUTES_PER_DAY);
      const intoDay = minutes - offset * MINUTES_PER_DAY;
      return intoDay < dayStartHour * 60 ? offset - 1 : offset;
    },
    [dayStartHour],
  );

  const sync = useCallback(() => {
    const el = scrollRef.current;
    if (!el) return;
    const top = el.scrollTop;

    if (targetRef.current !== null && Math.abs(top - targetRef.current) < 1) {
      targetRef.current = null;
    }

    const first = clampOffset(Math.floor(top / DAY_HEIGHT) - 1);
    const last = clampOffset(Math.floor((top + el.clientHeight) / DAY_HEIGHT) + 1);
    setRange((prev) =>
      prev.first === first && prev.last === last ? prev : { first, last },
    );

    const logical = clampOffset(logicalOffsetAt(top));
    if (logical !== reportedRef.current) {
      reportedRef.current = logical;
      onDayChange(addDays(epochDay, logical));
    }
  }, [epochDay, logicalOffsetAt, onDayChange]);

  function handleScroll() {
    if (frameRef.current) return;
    frameRef.current = requestAnimationFrame(() => {
      frameRef.current = 0;
      sync();
    });
  }

  /** Any hands-on scrolling abandons an in-flight programmatic one. */
  function handleUserInput() {
    targetRef.current = null;
  }

  const scrollToPx = useCallback((y: number) => {
    const el = scrollRef.current;
    if (!el) return;
    const target = Math.max(0, Math.min(el.scrollHeight - el.clientHeight, y));
    targetRef.current = target;
    el.scrollTo({
      top: target,
      behavior: Math.abs(target - el.scrollTop) <= SMOOTH_LIMIT ? "smooth" : "auto",
    });
  }, []);

  const shiftDays = useCallback(
    (n: number) => {
      const el = scrollRef.current;
      if (!el) return;
      scrollToPx((targetRef.current ?? el.scrollTop) + n * DAY_HEIGHT);
    },
    [scrollToPx],
  );

  useImperativeHandle(
    ref,
    () => ({
      shiftDays,
      goToDay(day) {
        const el = scrollRef.current;
        if (!el) return;
        const base = targetRef.current ?? el.scrollTop;
        shiftDays(clampOffset(offsetOf(day)) - logicalOffsetAt(base));
      },
      goToNow() {
        const el = scrollRef.current;
        if (!el) return;
        scrollToPx(yForInstant(Date.now()) - el.clientHeight / 2);
      },
    }),
    [logicalOffsetAt, offsetOf, scrollToPx, shiftDays, yForInstant],
  );

  // Open on the current moment, before the first paint.
  useLayoutEffect(() => {
    const el = scrollRef.current;
    if (!el) return;
    el.scrollTop = Math.max(0, yForInstant(Date.now()) - el.clientHeight / 2);
    sync();
    // Mount-only: later scrolls are driven by the user or the header.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Re-derive the visible window whenever the viewport or the day-start
  // cutoff changes (the latter arrives with the user's settings).
  useEffect(() => {
    reportedRef.current = null;
    sync();

    const el = scrollRef.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const observer = new ResizeObserver(() => sync());
    observer.observe(el);
    return () => observer.disconnect();
  }, [sync]);

  useEffect(() => () => cancelAnimationFrame(frameRef.current), []);

  // Split the fetched window into the days actually on screen. Anything
  // crossing midnight lands in both panes and is clipped by each.
  const panes = useMemo(() => {
    const out: {
      offset: number;
      day: Date;
      entries: TimeEntryDTO[];
      sleepEntries: SleepEntryDTO[];
    }[] = [];

    for (let offset = range.first; offset <= range.last; offset++) {
      const day = addDays(epochDay, offset);
      const startMs = startOfLocalDay(day).getTime();
      const endMs = startOfLocalDay(addDays(day, 1)).getTime();
      out.push({
        offset,
        day,
        entries: entries.filter((e) => {
          const start = Date.parse(e.startTime);
          const end = e.endTime ? Date.parse(e.endTime) : nowMs;
          return start < endMs && Math.max(end, start + 1) > startMs;
        }),
        sleepEntries: sleepEntries.filter(
          (s) =>
            Date.parse(s.startTime) < endMs && Date.parse(s.endTime) > startMs,
        ),
      });
    }
    return out;
  }, [range, epochDay, entries, sleepEntries, nowMs]);

  const draftKey = inlineDraft ? isoDateKey(inlineDraft.day) : null;

  return (
    <div
      ref={scrollRef}
      onScroll={handleScroll}
      onWheel={handleUserInput}
      onPointerDown={handleUserInput}
      className="scrollbar-none min-h-0 flex-1 overflow-y-auto overscroll-contain"
    >
      <div className="mx-auto w-full max-w-3xl px-4 md:px-8">
        {/* Panes mount and unmount as they scroll past; nothing reflows, and
            scroll anchoring stays out of the way. */}
        <div
          className="relative"
          style={{ height: SCROLL_HEIGHT, overflowAnchor: "none" }}
        >
          {panes.map((pane) => (
            <DayPane
              key={pane.offset}
              day={pane.day}
              offsetY={pane.offset * DAY_HEIGHT}
              dayStartHour={dayStartHour}
              entries={pane.entries}
              sleepEntries={pane.sleepEntries}
              categories={categories}
              nowMs={nowMs}
              inlineDraft={
                draftKey === isoDateKey(pane.day) ? inlineDraft : null
              }
              onOpenEntry={onOpenEntry}
              onOpenSleep={onOpenSleep}
              onCreateInline={onCreateInline}
              onChangeInlineRange={onChangeInlineRange}
              onChangeInlineDescription={onChangeInlineDescription}
              onApplyInlineSuggestion={onApplyInlineSuggestion}
              onSaveInline={onSaveInline}
              onExpandInline={onExpandInline}
              onCancelInline={onCancelInline}
              saving={saving}
            />
          ))}
        </div>
      </div>
    </div>
  );
}
