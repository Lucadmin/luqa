"use client";

import { Minus, Plus } from "lucide-react";
import { useCallback, useRef, useState } from "react";
import { cn } from "@/lib/cn";
import {
  clampToDay,
  formatClock,
  formatDuration,
  MINUTES_PER_DAY,
  SNAP_MINUTES,
} from "@/lib/time";

// One revolution = 60 minutes (like a real clock).
// Dragging past the top adds another hour, giving continuous accumulation.
const MINUTES_PER_REV = 60;
const SIZE = 248;
const STROKE = 14;
const R = (SIZE - STROKE) / 2 - 14; // ≈ 96
const CENTER = SIZE / 2;

type Handle = "start" | "end";

/** A read-only colored band on the dial showing another entry's time range. */
export interface DialSegment {
  startMin: number;
  endMin: number;
  color: string;
}

/** Clockwise angle from 12 o'clock for a minute value on the 60-min face. */
function angleFor(totalMinutes: number): number {
  const m = ((totalMinutes % MINUTES_PER_REV) + MINUTES_PER_REV) % MINUTES_PER_REV;
  return (m / MINUTES_PER_REV) * 2 * Math.PI;
}

/** Point on the ring for a given absolute-minute value (projected to 60-min face). */
function pointFor(totalMinutes: number, radius = R) {
  const a = angleFor(totalMinutes);
  return { x: CENTER + radius * Math.sin(a), y: CENTER - radius * Math.cos(a) };
}

/** Clockwise angle [0, 2π) from (x, y) offset relative to center. */
function angleFromXY(x: number, y: number): number {
  let a = Math.atan2(x, -y);
  if (a < 0) a += 2 * Math.PI;
  return a;
}

/** SVG arc for the fractional-minute span between two handles on the 60-min face. */
function fracArcPath(startMin: number, endMin: number, duration: number): string {
  const fracMin = duration % MINUTES_PER_REV;
  if (fracMin === 0) {
    if (duration === 0) return "";
    // Exactly full revolution(s): draw a full circle
    return `M ${CENTER} ${CENTER - R} A ${R} ${R} 0 1 1 ${CENTER - 0.001} ${CENTER - R}`;
  }
  const a = pointFor(startMin);
  const b = pointFor(endMin);
  const largeArc = fracMin > MINUTES_PER_REV / 2 ? 1 : 0;
  return `M ${a.x} ${a.y} A ${R} ${R} 0 ${largeArc} 1 ${b.x} ${b.y}`;
}

export function TimeDial({
  startMin,
  endMin,
  segments,
  onChange,
}: {
  startMin: number;
  endMin: number;
  segments?: DialSegment[];
  onChange: (start: number, end: number) => void;
}) {
  const svgRef = useRef<SVGSVGElement>(null);
  // Drag state lives in a ref to avoid re-renders on every pointer move
  const dragRef = useRef<{
    handle: Handle;
    prevAngle: number;
    totalMinutes: number; // unsnapped accumulator for smooth dragging
  } | null>(null);
  const [dragging, setDragging] = useState<Handle | null>(null);

  const duration = (endMin - startMin + MINUTES_PER_DAY) % MINUTES_PER_DAY;
  const completeRevs = Math.floor(duration / MINUTES_PER_REV);

  const getSvgOffset = useCallback((clientX: number, clientY: number) => {
    const svg = svgRef.current;
    if (!svg) return { x: 0, y: 0 };
    const rect = svg.getBoundingClientRect();
    const scale = SIZE / rect.width;
    return {
      x: (clientX - rect.left) * scale - CENTER,
      y: (clientY - rect.top) * scale - CENTER,
    };
  }, []);

  const onPointerDown = (handle: Handle) => (e: React.PointerEvent) => {
    e.preventDefault();
    (e.target as Element).setPointerCapture(e.pointerId);
    const { x, y } = getSvgOffset(e.clientX, e.clientY);
    dragRef.current = {
      handle,
      prevAngle: angleFromXY(x, y),
      totalMinutes: handle === "start" ? startMin : endMin,
    };
    setDragging(handle);
  };

  const onPointerMove = (e: React.PointerEvent) => {
    const state = dragRef.current;
    if (!state) return;

    const { x, y } = getSvgOffset(e.clientX, e.clientY);
    const newAngle = angleFromXY(x, y);

    // Clockwise delta, corrected for wrap-around at 0/2π boundary
    let delta = newAngle - state.prevAngle;
    if (delta > Math.PI) delta -= 2 * Math.PI;
    if (delta < -Math.PI) delta += 2 * Math.PI;

    state.prevAngle = newAngle;
    state.totalMinutes += (delta / (2 * Math.PI)) * MINUTES_PER_REV;

    const snapped = Math.round(state.totalMinutes / SNAP_MINUTES) * SNAP_MINUTES;
    const clamped = Math.max(0, Math.min(MINUTES_PER_DAY, snapped));

    if (state.handle === "start") {
      onChange(Math.min(clamped, endMin - SNAP_MINUTES), endMin);
    } else {
      onChange(startMin, Math.max(clamped, startMin + SNAP_MINUTES));
    }
  };

  const endDrag = () => {
    dragRef.current = null;
    setDragging(null);
  };

  const step = (handle: Handle, delta: number) => {
    if (handle === "start") {
      const s = clampToDay(startMin + delta);
      onChange(Math.min(s, endMin - SNAP_MINUTES), endMin);
    } else {
      const e = clampToDay(endMin + delta);
      onChange(startMin, Math.max(e, startMin + SNAP_MINUTES));
    }
  };

  const startPt = pointFor(startMin);
  const endPt = pointFor(endMin);

  return (
    <div className="flex flex-col items-center gap-4">
      <svg
        ref={svgRef}
        viewBox={`0 0 ${SIZE} ${SIZE}`}
        className="w-60 max-w-full touch-none select-none"
        onPointerMove={onPointerMove}
        onPointerUp={endDrag}
        onPointerCancel={endDrag}
      >
        {/* minute ticks — 12 marks (every 5 min), major at quarters */}
        {Array.from({ length: 12 }).map((_, i) => {
          const major = i % 3 === 0;
          const outer = pointFor(i * 5, R + STROKE / 2 + 2);
          const inner = pointFor(i * 5, R + STROKE / 2 + (major ? 9 : 5));
          return (
            <line
              key={i}
              x1={outer.x}
              y1={outer.y}
              x2={inner.x}
              y2={inner.y}
              className={major ? "stroke-faint" : "stroke-border"}
              strokeWidth={major ? 1.5 : 1}
            />
          );
        })}

        {/* quarter labels: 0, 15, 30, 45 */}
        {[0, 15, 30, 45].map((m) => {
          const p = pointFor(m, R + STROKE / 2 + 22);
          return (
            <text
              key={m}
              x={p.x}
              y={p.y}
              textAnchor="middle"
              dominantBaseline="central"
              className="fill-faint text-[10px] font-medium"
            >
              {m}
            </text>
          );
        })}

        {/* base track ring */}
        <circle
          cx={CENTER}
          cy={CENTER}
          r={R}
          fill="none"
          className="stroke-surface-2"
          strokeWidth={STROKE}
        />

        {/* segment overlays (projected to 60-min face for approximate context) */}
        {segments?.map((seg, i) => {
          const segDur = (seg.endMin - seg.startMin + MINUTES_PER_DAY) % MINUTES_PER_DAY;
          return (
            <path
              key={`seg-${i}`}
              d={fracArcPath(seg.startMin, seg.endMin, segDur)}
              fill="none"
              stroke={seg.color}
              strokeOpacity={0.4}
              strokeWidth={STROKE - 3}
              strokeLinecap="butt"
            />
          );
        })}

        {/* faint full-ring glow when duration spans complete hour(s) */}
        {completeRevs > 0 && (
          <circle
            cx={CENTER}
            cy={CENTER}
            r={R}
            fill="none"
            className="stroke-primary"
            strokeOpacity={0.18}
            strokeWidth={STROKE}
          />
        )}

        {/* fractional arc for the current partial hour */}
        <path
          d={fracArcPath(startMin, endMin, duration)}
          fill="none"
          className="stroke-primary"
          strokeWidth={STROKE}
          strokeLinecap="round"
        />

        {/* handles */}
        {(
          [
            ["start", startPt],
            ["end", endPt],
          ] as const
        ).map(([handle, pt]) => (
          <g key={handle}>
            <circle
              cx={pt.x}
              cy={pt.y}
              r={13}
              className={cn(
                "cursor-grab fill-surface stroke-primary",
                dragging === handle && "cursor-grabbing",
              )}
              strokeWidth={3}
              onPointerDown={onPointerDown(handle)}
            />
            <circle cx={pt.x} cy={pt.y} r={4} className="fill-primary" />
          </g>
        ))}

        {/* center readout */}
        <text
          x={CENTER}
          y={CENTER - 12}
          textAnchor="middle"
          className="fill-foreground text-[15px] font-semibold"
        >
          {formatClock(startMin)} – {formatClock(endMin)}
        </text>
        <text
          x={CENTER}
          y={CENTER + 12}
          textAnchor="middle"
          className="fill-muted text-[12px]"
        >
          {formatDuration(duration)}
        </text>
      </svg>

      {/* fine steppers */}
      <div className="flex items-center gap-6">
        {(["start", "end"] as const).map((handle) => (
          <div key={handle} className="flex flex-col items-center gap-1.5">
            <span className="text-[11px] font-medium uppercase tracking-wide text-faint">
              {handle}
            </span>
            <div className="flex items-center gap-1.5">
              <button
                type="button"
                aria-label={`${handle} minus 5 minutes`}
                onClick={() => step(handle, -SNAP_MINUTES)}
                className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground"
              >
                <Minus className="h-3.5 w-3.5" />
              </button>
              <span className="w-14 text-center text-sm font-medium tabular-nums">
                {formatClock(handle === "start" ? startMin : endMin)}
              </span>
              <button
                type="button"
                aria-label={`${handle} plus 5 minutes`}
                onClick={() => step(handle, SNAP_MINUTES)}
                className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground"
              >
                <Plus className="h-3.5 w-3.5" />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
