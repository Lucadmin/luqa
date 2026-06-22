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
  snapMinutes,
} from "@/lib/time";

const SIZE = 248;
const STROKE = 14;
const R = (SIZE - STROKE) / 2 - 14;
const CENTER = SIZE / 2;

type Handle = "start" | "end";

/** Point on the dial circle for a given minutes-since-midnight value. */
function pointFor(minutes: number, radius = R) {
  const angle = (minutes / MINUTES_PER_DAY) * 2 * Math.PI; // clockwise from top
  return {
    x: CENTER + radius * Math.sin(angle),
    y: CENTER - radius * Math.cos(angle),
  };
}

function arcPath(startMin: number, endMin: number) {
  const a = pointFor(startMin);
  const b = pointFor(endMin);
  const delta = (endMin - startMin + MINUTES_PER_DAY) % MINUTES_PER_DAY;
  const largeArc = delta > MINUTES_PER_DAY / 2 ? 1 : 0;
  return `M ${a.x} ${a.y} A ${R} ${R} 0 ${largeArc} 1 ${b.x} ${b.y}`;
}

export function TimeDial({
  startMin,
  endMin,
  onChange,
}: {
  startMin: number;
  endMin: number;
  onChange: (start: number, end: number) => void;
}) {
  const svgRef = useRef<SVGSVGElement>(null);
  const [dragging, setDragging] = useState<Handle | null>(null);

  const minutesFromPointer = useCallback((clientX: number, clientY: number) => {
    const svg = svgRef.current;
    if (!svg) return 0;
    const rect = svg.getBoundingClientRect();
    const scale = SIZE / rect.width;
    const x = (clientX - rect.left) * scale - CENTER;
    const y = (clientY - rect.top) * scale - CENTER;
    let angle = Math.atan2(x, -y); // clockwise from top, [-π, π]
    if (angle < 0) angle += 2 * Math.PI;
    const minutes = (angle / (2 * Math.PI)) * MINUTES_PER_DAY;
    return snapMinutes(minutes);
  }, []);

  const applyHandle = useCallback(
    (handle: Handle, minutes: number) => {
      if (handle === "start") {
        const s = clampToDay(Math.min(minutes, endMin - SNAP_MINUTES));
        onChange(s, endMin);
      } else {
        const e = clampToDay(Math.max(minutes, startMin + SNAP_MINUTES));
        onChange(startMin, e);
      }
    },
    [startMin, endMin, onChange],
  );

  const onPointerDown = (handle: Handle) => (e: React.PointerEvent) => {
    e.preventDefault();
    (e.target as Element).setPointerCapture(e.pointerId);
    setDragging(handle);
  };

  const onPointerMove = (e: React.PointerEvent) => {
    if (!dragging) return;
    applyHandle(dragging, minutesFromPointer(e.clientX, e.clientY));
  };

  const endDrag = () => setDragging(null);

  const step = (handle: Handle, delta: number) => {
    if (handle === "start") {
      applyHandle("start", startMin + delta);
    } else {
      applyHandle("end", endMin + delta);
    }
  };

  const startPt = pointFor(startMin);
  const endPt = pointFor(endMin);
  const duration = (endMin - startMin + MINUTES_PER_DAY) % MINUTES_PER_DAY;

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
        {/* hour ticks */}
        {Array.from({ length: 24 }).map((_, h) => {
          const major = h % 6 === 0;
          const outer = pointFor(h * 60, R + STROKE / 2 + 2);
          const inner = pointFor(h * 60, R + STROKE / 2 + (major ? 9 : 5));
          return (
            <line
              key={h}
              x1={outer.x}
              y1={outer.y}
              x2={inner.x}
              y2={inner.y}
              className={major ? "stroke-faint" : "stroke-border"}
              strokeWidth={major ? 1.5 : 1}
            />
          );
        })}
        {/* quarter labels */}
        {[0, 6, 12, 18].map((h) => {
          const p = pointFor(h * 60, R + STROKE / 2 + 22);
          return (
            <text
              key={h}
              x={p.x}
              y={p.y}
              textAnchor="middle"
              dominantBaseline="central"
              className="fill-faint text-[10px] font-medium"
            >
              {h === 0 ? "0" : h}
            </text>
          );
        })}

        {/* track */}
        <circle
          cx={CENTER}
          cy={CENTER}
          r={R}
          fill="none"
          className="stroke-surface-2"
          strokeWidth={STROKE}
        />
        {/* active arc */}
        <path
          d={arcPath(startMin, endMin)}
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
