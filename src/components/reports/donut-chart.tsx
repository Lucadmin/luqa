"use client";

import { useState } from "react";
import { formatDuration } from "@/lib/time";

const SIZE = 180;
const STROKE = 28;
const R = (SIZE - STROKE) / 2;
const CIRC = 2 * Math.PI * R;
const CENTER = SIZE / 2;

interface Segment {
  catId: string;
  name: string;
  color: string;
  minutes: number;
  pct: number;
}

export function DonutChart({
  segments,
  totalMinutes,
}: {
  segments: Segment[];
  totalMinutes: number;
}) {
  const [hovered, setHovered] = useState<string | null>(null);

  const active = hovered ? segments.find((s) => s.catId === hovered) : null;

  const arcs = segments.reduce<
    Array<{ catId: string; name: string; color: string; minutes: number; pct: number; dash: number; gap: number; offset: number }>
  >((acc, seg) => {
    const dash = (seg.pct / 100) * CIRC;
    const prev = acc[acc.length - 1];
    const arcOffset = prev ? prev.offset + prev.dash : 0;
    acc.push({ ...seg, dash, gap: CIRC - dash, offset: arcOffset });
    return acc;
  }, []);

  return (
    <div className="flex flex-col items-center gap-6 sm:flex-row sm:items-start sm:gap-10">
      {/* donut */}
      <div className="relative shrink-0">
        <svg width={SIZE} height={SIZE} className="-rotate-90">
          {/* track */}
          <circle
            cx={CENTER}
            cy={CENTER}
            r={R}
            fill="none"
            className="stroke-surface-2"
            strokeWidth={STROKE}
          />
          {arcs.map((arc) => (
            <circle
              key={arc.catId}
              cx={CENTER}
              cy={CENTER}
              r={R}
              fill="none"
              stroke={arc.color}
              strokeWidth={hovered && hovered !== arc.catId ? STROKE - 4 : STROKE}
              strokeDasharray={`${arc.dash} ${arc.gap}`}
              strokeDashoffset={-arc.offset}
              strokeLinecap="butt"
              className="cursor-pointer transition-all duration-150"
              onMouseEnter={() => setHovered(arc.catId)}
              onMouseLeave={() => setHovered(null)}
            />
          ))}
        </svg>
        {/* center readout */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          {active ? (
            <>
              <span className="text-xs font-medium text-muted">{active.name}</span>
              <span className="text-base font-bold tabular-nums">
                {formatDuration(active.minutes)}
              </span>
              <span className="text-xs text-faint">{Math.round(active.pct)}%</span>
            </>
          ) : (
            <>
              <span className="text-xs text-faint">Total</span>
              <span className="text-base font-bold tabular-nums">
                {formatDuration(totalMinutes)}
              </span>
            </>
          )}
        </div>
      </div>

      {/* legend */}
      <div className="flex flex-col gap-2">
        {segments.map((seg) => (
          <button
            key={seg.catId}
            type="button"
            className="flex items-center gap-2.5 text-left"
            onMouseEnter={() => setHovered(seg.catId)}
            onMouseLeave={() => setHovered(null)}
          >
            <span
              className="h-2.5 w-2.5 shrink-0 rounded-full transition-transform"
              style={{
                backgroundColor: seg.color,
                transform: hovered === seg.catId ? "scale(1.3)" : "scale(1)",
              }}
            />
            <span
              className={`flex-1 text-sm transition-colors ${
                hovered && hovered !== seg.catId ? "text-faint" : "text-foreground"
              }`}
            >
              {seg.name}
            </span>
            <span className="ml-4 text-sm tabular-nums text-muted">
              {formatDuration(seg.minutes)}
            </span>
            <span className="w-8 text-right text-xs tabular-nums text-faint">
              {Math.round(seg.pct)}%
            </span>
          </button>
        ))}
      </div>
    </div>
  );
}
