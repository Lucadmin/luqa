"use client";

import {
  forwardRef,
  useCallback,
  useEffect,
  useImperativeHandle,
  useLayoutEffect,
  useRef,
  useState,
} from "react";
import { blendPeriodColor, type PeriodRange, WEEKS_PER_YEAR } from "@/lib/life";

export interface LifeWallHandle {
  /** Briefly outlines a year row — feedback after a jump triggered elsewhere
   * (a period chip, "Today") so it's obvious where the strip below just went. */
  flashRow: (row: number) => void;
}

interface LifeWallProps {
  totalWeeks: number;
  currentWeek: number;
  cellPeriods: PeriodRange[][];
  noteWeeks: Set<number>;
  milestoneWeeks: Set<number>;
  /** Row/col hit while tapping or dragging across the wall. */
  onFocusWeek: (weekIndex: number) => void;
  /** Short label for the drag magnifier, e.g. "Age 14 · Studying + Berlin". */
  labelFor: (weekIndex: number) => string;
}

interface Geometry {
  cell: number;
  gap: number;
  rowCell: number;
  rowGap: number;
  rows: number;
}

function useElementSize<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const [size, setSize] = useState({ width: 0, height: 0 });
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    const update = () => setSize({ width: el.clientWidth, height: el.clientHeight });
    update();
    const ro = new ResizeObserver(update);
    ro.observe(el);
    return () => ro.disconnect();
  }, []);
  return [ref, size] as const;
}

function withAlpha(hex: string, alpha: number): string {
  const h = hex.replace("#", "");
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function roundRectPath(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.arcTo(x + w, y, x + w, y + h, r);
  ctx.arcTo(x + w, y + h, x, y + h, r);
  ctx.arcTo(x, y + h, x, y, r);
  ctx.arcTo(x, y, x + w, y, r);
  ctx.closePath();
}

function FlashOverlay({ top, height, onDone }: { top: number; height: number; onDone: () => void }) {
  const [visible, setVisible] = useState(true);
  useEffect(() => {
    const raf = requestAnimationFrame(() => setVisible(false));
    const timeout = setTimeout(onDone, 800);
    return () => {
      cancelAnimationFrame(raf);
      clearTimeout(timeout);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return (
    <div
      aria-hidden
      className="pointer-events-none absolute inset-x-0 rounded-sm bg-primary/15 ring-[1.5px] ring-primary transition-opacity duration-700 ease-out"
      style={{ top, height, opacity: visible ? 1 : 0 }}
    />
  );
}

export const LifeWall = forwardRef<LifeWallHandle, LifeWallProps>(function LifeWall(
  { totalWeeks, currentWeek, cellPeriods, noteWeeks, milestoneWeeks, onFocusWeek, labelFor },
  ref,
) {
  const [wrapRef, size] = useElementSize<HTMLDivElement>();
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const geoRef = useRef<Geometry>({ cell: 0, gap: 0, rowCell: 0, rowGap: 0, rows: 0 });
  const [magnifier, setMagnifier] = useState<{ x: number; y: number; text: string } | null>(null);
  const [flash, setFlash] = useState<{ top: number; height: number; id: number } | null>(null);

  const rows = Math.ceil(totalWeeks / WEEKS_PER_YEAR);

  const draw = useCallback(() => {
    const canvas = canvasRef.current;
    if (!canvas || size.width === 0 || size.height === 0) return;
    const dpr = window.devicePixelRatio || 1;
    canvas.width = Math.round(size.width * dpr);
    canvas.height = Math.round(size.height * dpr);
    canvas.style.width = `${size.width}px`;
    canvas.style.height = `${size.height}px`;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, size.width, size.height);

    const styles = getComputedStyle(document.documentElement);
    const foreground = styles.getPropertyValue("--foreground").trim() || "#1a1a1e";
    const borderStrong = styles.getPropertyValue("--border-strong").trim() || "#d6d6da";
    const surface2 = styles.getPropertyValue("--surface-2").trim() || "#f4f4f5";
    const primary = styles.getPropertyValue("--primary").trim() || "#6366f1";

    const pitch = size.width / WEEKS_PER_YEAR;
    const gap = Math.max(0.5, pitch * 0.16);
    const cell = Math.max(1, pitch - gap);
    const rowPitch = size.height / rows;
    const rowGap = Math.max(0.5, rowPitch * 0.16);
    const rowCell = Math.max(1, rowPitch - rowGap);
    const radius = Math.max(0.5, Math.min(cell, rowCell) * 0.25);
    geoRef.current = { cell, gap, rowCell, rowGap, rows };

    const currentRow = Math.floor(currentWeek / WEEKS_PER_YEAR);

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < WEEKS_PER_YEAR; col++) {
        const i = row * WEEKS_PER_YEAR + col;
        if (i >= totalWeeks) continue;
        const x = col * (cell + gap);
        const y = row * (rowCell + rowGap) + rowGap / 2;
        const fill = blendPeriodColor((cellPeriods[i] ?? []).map((p) => p.color));
        const lived = i <= currentWeek;

        roundRectPath(ctx, x, y, cell, rowCell, radius);
        ctx.fillStyle = fill ?? (lived ? withAlpha(foreground, 0.3) : surface2);
        ctx.fill();
        if (!fill && !lived) {
          ctx.lineWidth = 1;
          ctx.strokeStyle = borderStrong;
          ctx.stroke();
        }
        if (col === 0) {
          roundRectPath(ctx, x, y, cell, rowCell, radius);
          ctx.lineWidth = 1;
          ctx.strokeStyle = withAlpha(primary, 0.55);
          ctx.stroke();
        }
        if (noteWeeks.has(i) && i !== currentWeek && cell > 3) {
          roundRectPath(ctx, x + 0.75, y + 0.75, cell - 1.5, rowCell - 1.5, Math.max(0, radius - 0.75));
          ctx.lineWidth = 1;
          ctx.strokeStyle = withAlpha(foreground, 0.55);
          ctx.stroke();
        }
        if (i === currentWeek) {
          roundRectPath(ctx, x - 1, y - 1, cell + 2, rowCell + 2, radius + 1);
          ctx.lineWidth = 1.6;
          ctx.strokeStyle = primary;
          ctx.stroke();
        }
        if (milestoneWeeks.has(i) && Math.min(cell, rowCell) > 2.5) {
          ctx.beginPath();
          ctx.arc(x + cell / 2, y + rowCell / 2, Math.max(0.6, Math.min(cell, rowCell) * 0.22), 0, Math.PI * 2);
          ctx.fillStyle = "#ffffff";
          ctx.fill();
        }
      }
      if (row === currentRow) {
        ctx.fillStyle = withAlpha(primary, 0.06);
        ctx.fillRect(0, row * (rowCell + rowGap), size.width, rowCell + rowGap);
      }
    }
  }, [size, rows, totalWeeks, currentWeek, cellPeriods, noteWeeks, milestoneWeeks]);

  useEffect(() => {
    draw();
  }, [draw]);

  // Canvas pixels don't react to theme changes on their own — repaint when
  // next-themes flips the `.dark` class or the OS preference changes.
  useEffect(() => {
    const mq = window.matchMedia("(prefers-color-scheme: dark)");
    const onChange = () => draw();
    mq.addEventListener("change", onChange);
    const observer = new MutationObserver(onChange);
    observer.observe(document.documentElement, { attributes: true, attributeFilter: ["class", "data-theme"] });
    return () => {
      mq.removeEventListener("change", onChange);
      observer.disconnect();
    };
  }, [draw]);

  const hitTest = useCallback(
    (clientX: number, clientY: number) => {
      const canvas = canvasRef.current;
      const { cell, gap, rowCell, rowGap, rows: geoRows } = geoRef.current;
      if (!canvas || cell === 0) return null;
      const rect = canvas.getBoundingClientRect();
      const col = Math.floor((clientX - rect.left) / (cell + gap));
      const row = Math.floor((clientY - rect.top) / (rowCell + rowGap));
      if (col < 0 || col >= WEEKS_PER_YEAR || row < 0 || row >= geoRows) return null;
      const index = row * WEEKS_PER_YEAR + col;
      if (index >= totalWeeks) return null;
      return { row, col, index };
    },
    [totalWeeks],
  );

  const draggingRef = useRef(false);
  const movedRef = useRef(false);
  const startRef = useRef({ x: 0, y: 0 });

  function onPointerDown(e: React.PointerEvent<HTMLCanvasElement>) {
    draggingRef.current = true;
    movedRef.current = false;
    startRef.current = { x: e.clientX, y: e.clientY };
    e.currentTarget.setPointerCapture(e.pointerId);
  }

  function onPointerMove(e: React.PointerEvent<HTMLCanvasElement>) {
    if (!draggingRef.current) return;
    const dx = e.clientX - startRef.current.x;
    const dy = e.clientY - startRef.current.y;
    if (Math.hypot(dx, dy) > 6) movedRef.current = true;
    if (!movedRef.current) return;
    const hit = hitTest(e.clientX, e.clientY);
    if (!hit) return;
    const wrapRect = wrapRef.current?.getBoundingClientRect();
    setMagnifier({
      x: e.clientX - (wrapRect?.left ?? 0),
      y: e.clientY - (wrapRect?.top ?? 0),
      text: labelFor(hit.index),
    });
  }

  function onPointerUp(e: React.PointerEvent<HTMLCanvasElement>) {
    if (!draggingRef.current) return;
    draggingRef.current = false;
    const hit = hitTest(e.clientX, e.clientY);
    setMagnifier(null);
    if (hit) onFocusWeek(hit.index);
  }

  useImperativeHandle(ref, () => ({
    flashRow(row: number) {
      const { rowCell, rowGap } = geoRef.current;
      setFlash({ top: row * (rowCell + rowGap), height: rowCell, id: Date.now() });
    },
  }));

  return (
    <div ref={wrapRef} className="relative h-full w-full">
      <canvas
        ref={canvasRef}
        aria-label={`Life in weeks overview, ${rows} years. Drag to preview a year, release to jump the strip below to it.`}
        className="block h-full w-full touch-none"
        onPointerDown={onPointerDown}
        onPointerMove={onPointerMove}
        onPointerUp={onPointerUp}
        onPointerCancel={() => {
          draggingRef.current = false;
          setMagnifier(null);
        }}
      />
      {magnifier && (
        <div
          aria-hidden
          className="pointer-events-none absolute z-10 -translate-x-1/2 translate-y-[-135%] whitespace-nowrap rounded-lg bg-foreground px-2.5 py-1.5 text-xs font-semibold text-background shadow-lg"
          style={{ left: magnifier.x, top: magnifier.y }}
        >
          {magnifier.text}
        </div>
      )}
      {flash && (
        <FlashOverlay
          key={flash.id}
          top={flash.top}
          height={flash.height}
          onDone={() => setFlash(null)}
        />
      )}
    </div>
  );
});
