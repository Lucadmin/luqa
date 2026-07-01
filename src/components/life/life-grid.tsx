"use client";

import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { cn } from "@/lib/cn";
import { WEEKS_PER_YEAR } from "@/lib/life";

const GUTTER = 22; // px reserved for age labels down the left edge

interface LifeGridProps {
  totalWeeks: number;
  currentWeek: number;
  /** Per-cell band colour, or null. Length === totalWeeks. */
  cellColors: (string | null)[];
  noteWeeks: Set<number>;
  milestoneWeeks: Set<number>;
  /** Cell size multiplier over the fit-to-width size. 1 = fit. */
  zoom: number;
  /** Called with a new (unclamped) zoom during a pinch gesture. */
  onZoomChange: (zoom: number) => void;
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

function touchDistance(touches: TouchList): number {
  const dx = touches[0].clientX - touches[1].clientX;
  const dy = touches[0].clientY - touches[1].clientY;
  return Math.hypot(dx, dy);
}

export function LifeGrid({
  totalWeeks,
  currentWeek,
  cellColors,
  noteWeeks,
  milestoneWeeks,
  zoom,
  onZoomChange,
  selectedWeek,
  onSelect,
  labelFor,
}: LifeGridProps) {
  const [ref, width] = useWidth<HTMLDivElement>();

  // Two-finger pinch to zoom. Bound as a non-passive native listener so we can
  // stop the browser's own page zoom while pinching the grid.
  const zoomRef = useRef(zoom);
  const onZoomRef = useRef(onZoomChange);
  useEffect(() => {
    zoomRef.current = zoom;
    onZoomRef.current = onZoomChange;
  });
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    let startDist = 0;
    let startZoom = 1;
    const onStart = (e: TouchEvent) => {
      if (e.touches.length === 2) {
        startDist = touchDistance(e.touches);
        startZoom = zoomRef.current;
      }
    };
    const onMove = (e: TouchEvent) => {
      if (e.touches.length === 2 && startDist > 0) {
        e.preventDefault();
        const ratio = touchDistance(e.touches) / startDist;
        onZoomRef.current(startZoom * ratio);
      }
    };
    const onEnd = (e: TouchEvent) => {
      if (e.touches.length < 2) startDist = 0;
    };
    el.addEventListener("touchstart", onStart, { passive: false });
    el.addEventListener("touchmove", onMove, { passive: false });
    el.addEventListener("touchend", onEnd);
    el.addEventListener("touchcancel", onEnd);
    return () => {
      el.removeEventListener("touchstart", onStart);
      el.removeEventListener("touchmove", onMove);
      el.removeEventListener("touchend", onEnd);
      el.removeEventListener("touchcancel", onEnd);
    };
  }, [ref]);

  const rows = Math.ceil(totalWeeks / WEEKS_PER_YEAR);

  // Base geometry at zoom 1: a fractional cell size chosen so the 52 columns
  // exactly fill the available width (no flooring, so no wasted side margin).
  const avail = width > 0 ? width - 1 : 0;
  const pitch = avail > 0 ? (avail - GUTTER) / WEEKS_PER_YEAR : 12;
  const gap = Math.max(0.5, pitch * 0.12);
  const cell = Math.max(2, pitch - gap);
  const radius = Math.max(1, cell * 0.22);
  const baseW = GUTTER + WEEKS_PER_YEAR * (cell + gap);
  const baseH = rows * cell + (rows - 1) * gap;

  // The cells never depend on zoom — zoom is applied purely via a CSS transform
  // on the wrapper — so pinching doesn't re-render thousands of nodes.
  const children = useMemo(() => {
    const out: React.ReactNode[] = [];
    for (let row = 0; row < rows; row++) {
      out.push(
        <div
          key={`l${row}`}
          className="flex items-center justify-end pr-1 text-[10px] leading-none text-faint tabular-nums"
          style={{ height: cell }}
        >
          {row % 10 === 0 ? row : ""}
        </div>,
      );
      for (let col = 0; col < WEEKS_PER_YEAR; col++) {
        const i = row * WEEKS_PER_YEAR + col;
        if (i >= totalWeeks) {
          out.push(<div key={i} />);
          continue;
        }
        const lived = i <= currentWeek;
        const fill = cellColors[i];
        const isCurrent = i === currentWeek;
        const isSelected = i === selectedWeek;
        const hasNote = noteWeeks.has(i);
        const isMilestone = milestoneWeeks.has(i);
        out.push(
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
              "relative",
              !fill && (lived ? "bg-foreground/25" : "bg-transparent"),
              !lived && "border border-border/60",
              hasNote && !isCurrent && "ring-1 ring-inset ring-foreground/70",
              isCurrent && "z-10 ring-2 ring-primary",
              isSelected && "z-20 outline outline-2 outline-offset-1 outline-primary",
            )}
          >
            {isMilestone && (
              <span
                aria-hidden
                className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white shadow ring-1 ring-black/30"
                style={{ width: Math.max(2, cell * 0.42), height: Math.max(2, cell * 0.42) }}
              />
            )}
          </button>,
        );
      }
    }
    return out;
  }, [
    rows,
    totalWeeks,
    cell,
    radius,
    currentWeek,
    cellColors,
    noteWeeks,
    milestoneWeeks,
    selectedWeek,
    onSelect,
    labelFor,
  ]);

  return (
    <div
      ref={ref}
      className="h-full w-full overflow-auto"
      style={{ touchAction: "pan-x pan-y" }}
    >
      {avail > 0 && (
        <div style={{ width: baseW * zoom, height: baseH * zoom }}>
          <div
            className="grid"
            style={{
              transform: `scale(${zoom})`,
              transformOrigin: "top left",
              gridTemplateColumns: `${GUTTER}px repeat(${WEEKS_PER_YEAR}, ${cell}px)`,
              gridAutoRows: `${cell}px`,
              gap: `${gap}px`,
            }}
          >
            {children}
          </div>
        </div>
      )}
    </div>
  );
}
