"use client";

import {
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { cn } from "@/lib/cn";
import { WEEKS_PER_YEAR } from "@/lib/life";

const GUTTER = 46; // px reserved for age labels down the left edge
const HEADER = 26;
const MIN_PITCH = 7;

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
  onPreview: (weekIndex: number | null) => void;
  labelFor: (weekIndex: number) => string;
  /** Incremented when the current week should be scrolled into view. */
  scrollRequest: number;
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
  onPreview,
  labelFor,
  scrollRequest,
}: LifeGridProps) {
  const [ref, width] = useWidth<HTMLDivElement>();
  const [activeWeek, setActiveWeek] = useState(currentWeek);
  const handledScrollRequest = useRef(0);

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

  useEffect(() => {
    if (
      scrollRequest === 0 ||
      scrollRequest === handledScrollRequest.current ||
      width === 0
    ) {
      return;
    }
    handledScrollRequest.current = scrollRequest;
    const cell = ref.current?.querySelector<HTMLElement>(
      `[data-week-index="${currentWeek}"]`,
    );
    cell?.focus({ preventScroll: true });
    cell?.scrollIntoView({
      behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches
        ? "auto"
        : "smooth",
      block: "center",
      inline: "center",
    });
  }, [currentWeek, scrollRequest, width, ref]);

  const rows = Math.ceil(totalWeeks / WEEKS_PER_YEAR);

  // Base geometry at zoom 1: a fractional cell size chosen so the 52 columns
  // fill the available width. A small minimum keeps mobile cells visible;
  // narrow screens can pan horizontally instead of collapsing into noise.
  const avail = width > 0 ? width - 1 : 0;
  const pitch =
    avail > 0
      ? Math.max(MIN_PITCH, (avail - GUTTER) / WEEKS_PER_YEAR)
      : 12;
  const gap = Math.max(0.5, pitch * 0.12);
  const cell = Math.max(2, pitch - gap);
  const radius = Math.max(1, cell * 0.22);
  const baseW = GUTTER + WEEKS_PER_YEAR * (cell + gap);
  const baseH = gap + rows * cell + (rows - 1) * gap;

  const moveFocus = useCallback(
    (from: number, key: string) => {
      const rowStart = Math.floor(from / WEEKS_PER_YEAR) * WEEKS_PER_YEAR;
      const rowEnd = Math.min(
        totalWeeks - 1,
        rowStart + WEEKS_PER_YEAR - 1,
      );
      let next = from;

      if (key === "ArrowLeft") next = Math.max(0, from - 1);
      if (key === "ArrowRight") next = Math.min(totalWeeks - 1, from + 1);
      if (key === "ArrowUp") next = Math.max(0, from - WEEKS_PER_YEAR);
      if (key === "ArrowDown") {
        next = Math.min(totalWeeks - 1, from + WEEKS_PER_YEAR);
      }
      if (key === "Home") next = rowStart;
      if (key === "End") next = rowEnd;
      if (next === from) return;

      setActiveWeek(next);
      onPreview(next);
      requestAnimationFrame(() => {
        ref.current
          ?.querySelector<HTMLElement>(`[data-week-index="${next}"]`)
          ?.focus();
      });
    },
    [onPreview, ref, totalWeeks],
  );

  const tabbableWeek = activeWeek < totalWeeks ? activeWeek : currentWeek;

  // The cells never depend on zoom — zoom is applied purely via a CSS transform
  // on the wrapper — so pinching doesn't re-render thousands of nodes.
  const children = useMemo(() => {
    const out: React.ReactNode[] = [];
    for (let row = 0; row < rows; row++) {
      out.push(
        <div
          key={`l${row}`}
          className="flex items-center justify-end pr-1 text-[10px] leading-none text-muted tabular-nums"
          style={{ height: cell }}
        >
          {row % 5 === 0 || row === Math.floor(currentWeek / WEEKS_PER_YEAR)
            ? row
            : ""}
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
        const isBirthday = col === 0;
        out.push(
          <button
            key={i}
            type="button"
            title={labelFor(i)}
            aria-label={labelFor(i)}
            aria-current={isCurrent ? "date" : undefined}
            data-week-index={i}
            tabIndex={i === tabbableWeek ? 0 : -1}
            onFocus={() => {
              setActiveWeek(i);
              onPreview(i);
            }}
            onPointerEnter={() => onPreview(i)}
            onClick={() => {
              setActiveWeek(i);
              onPreview(i);
              onSelect(i);
            }}
            onKeyDown={(event) => {
              if (
                event.key.startsWith("Arrow") ||
                event.key === "Home" ||
                event.key === "End"
              ) {
                event.preventDefault();
                moveFocus(i, event.key);
              }
            }}
            style={{
              width: cell,
              height: cell,
              borderRadius: radius,
              backgroundColor: fill ?? undefined,
            }}
            className={cn(
              "relative transition-[background-color,box-shadow,outline] duration-150 motion-reduce:transition-none focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-primary",
              !fill && (lived ? "bg-foreground/30" : "bg-surface"),
              !lived && !fill && "border border-border-strong",
              isBirthday && "ring-1 ring-inset ring-primary/70",
              hasNote && !isCurrent && "ring-1 ring-inset ring-foreground/70",
              isCurrent &&
                "z-10 ring-2 ring-primary ring-offset-1 ring-offset-background",
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
    tabbableWeek,
    onSelect,
    onPreview,
    moveFocus,
    labelFor,
  ]);

  const headerTicks = [
    { col: 0, label: "Birthday", align: "start" },
    { col: 12, label: "13w", align: "center" },
    { col: 25, label: "26w", align: "center" },
    { col: 38, label: "39w", align: "center" },
    { col: 51, label: "52w", align: "end" },
  ] as const;

  return (
    <div
      ref={ref}
      aria-label="Life in weeks. Use arrow keys to move between weeks, then press Enter to open a review."
      className="h-full w-full overflow-auto overscroll-contain"
      onPointerLeave={() => onPreview(null)}
      style={{ touchAction: "pan-x pan-y" }}
    >
      {avail > 0 && (
        <div
          style={{
            width: baseW * zoom,
            height: (HEADER + baseH) * zoom,
          }}
        >
          <div
            style={{
              width: baseW,
              transform: `scale(${zoom})`,
              transformOrigin: "top left",
            }}
          >
            <div
              className="sticky top-0 z-30 border-b border-border bg-background/95 text-[10px] font-medium text-muted"
              style={{ width: baseW, height: HEADER }}
            >
              <span className="absolute inset-y-0 left-0 flex items-center">
                Age
              </span>
              {headerTicks.map(({ col, label, align }) => (
                <span
                  key={label}
                  className="absolute inset-y-0 flex items-center whitespace-nowrap"
                  style={{
                    left: GUTTER + col * (cell + gap),
                    transform:
                      align === "center"
                        ? "translateX(-50%)"
                        : align === "end"
                          ? "translateX(-100%)"
                          : undefined,
                  }}
                >
                  {label}
                </span>
              ))}
            </div>
            <div
              className="grid"
              style={{
                gridTemplateColumns: `${GUTTER}px repeat(${WEEKS_PER_YEAR}, ${cell}px)`,
                gridAutoRows: `${cell}px`,
                gap: `${gap}px`,
                paddingTop: gap,
              }}
            >
              {children}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
