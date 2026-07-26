"use client";

import { useState } from "react";
import { cn } from "@/lib/cn";
import { formatWeight } from "@/lib/gym";
import { formatDayLabel } from "@/lib/time";
import type { ExercisePointDTO } from "@/lib/types";

export type Metric = "estimated" | "weight" | "volume" | "reps";

export const METRIC_LABELS: Record<Metric, string> = {
  estimated: "Est. 1RM",
  weight: "Top weight",
  volume: "Volume",
  reps: "Reps",
};

export function metricValue(point: ExercisePointDTO, metric: Metric): number | null {
  switch (metric) {
    case "estimated":
      return point.best1RM;
    case "weight":
      return point.topWeight;
    case "volume":
      return point.volume > 0 ? point.volume : null;
    case "reps":
      return point.totalReps > 0 ? point.totalReps : null;
  }
}

const WIDTH = 320;
const HEIGHT = 108;
const PAD_X = 6;
const PAD_Y = 10;

/**
 * Progress over time for one exercise. Sessions are spaced evenly rather than
 * by real date — with gaps of months in the log, a true time axis squashes
 * everything recent into the last few pixels.
 */
export function ProgressChart({
  points,
  metric,
  selectedId,
  onSelect,
}: {
  points: ExercisePointDTO[];
  metric: Metric;
  selectedId?: string | null;
  onSelect?: (point: ExercisePointDTO) => void;
}) {
  const [hovered, setHovered] = useState<number | null>(null);

  const plotted = points
    .map((point, index) => ({ point, index, value: metricValue(point, metric) }))
    .filter((p): p is { point: ExercisePointDTO; index: number; value: number } =>
      p.value !== null,
    );

  if (plotted.length < 2) {
    return (
      <div className="flex h-[108px] items-center justify-center rounded-xl border border-dashed border-border text-xs text-faint">
        {plotted.length === 0
          ? "No numbers to plot yet"
          : "One session so far — the line starts at two"}
      </div>
    );
  }

  const values = plotted.map((p) => p.value);
  const min = Math.min(...values);
  const max = Math.max(...values);
  // A flat line should sit in the middle, not divide by zero.
  const span = max - min || Math.max(1, max * 0.1);

  const x = (i: number) =>
    PAD_X + (i / (plotted.length - 1)) * (WIDTH - PAD_X * 2);
  const y = (value: number) =>
    HEIGHT - PAD_Y - ((value - min) / span) * (HEIGHT - PAD_Y * 2);

  const line = plotted
    .map((p, i) => `${i === 0 ? "M" : "L"}${x(i).toFixed(1)},${y(p.value).toFixed(1)}`)
    .join(" ");

  const area = `${line} L${x(plotted.length - 1).toFixed(1)},${HEIGHT} L${x(0).toFixed(1)},${HEIGHT} Z`;

  const active = hovered ?? plotted.length - 1;
  const activePoint = plotted[active];

  return (
    <div className="flex flex-col gap-1">
      <div className="flex items-baseline justify-between text-xs">
        <span className="font-medium tabular-nums">
          {formatWeight(activePoint.value)}
          <span className="ml-1 font-normal text-faint">
            {METRIC_LABELS[metric]}
          </span>
        </span>
        <span className="text-faint">{formatDayLabel(activePoint.point.date)}</span>
      </div>

      <svg
        viewBox={`0 0 ${WIDTH} ${HEIGHT}`}
        className="h-[108px] w-full touch-none"
        preserveAspectRatio="none"
        role="img"
        aria-label={`${METRIC_LABELS[metric]} over ${plotted.length} sessions`}
        onMouseLeave={() => setHovered(null)}
      >
        <defs>
          <linearGradient id="gym-progress-fill" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" stopColor="var(--color-primary)" stopOpacity="0.18" />
            <stop offset="100%" stopColor="var(--color-primary)" stopOpacity="0" />
          </linearGradient>
        </defs>

        <path d={area} fill="url(#gym-progress-fill)" />
        <path
          d={line}
          fill="none"
          stroke="var(--color-primary)"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          vectorEffect="non-scaling-stroke"
        />

        {plotted.map((p, i) => {
          const isActive = i === active;
          const isSelected = selectedId === p.point.sessionId;
          return (
            <g key={p.point.sessionId}>
              {/* a generous invisible target — the dots themselves are tiny */}
              <rect
                x={x(i) - (WIDTH - PAD_X * 2) / (plotted.length - 1) / 2}
                y={0}
                width={(WIDTH - PAD_X * 2) / (plotted.length - 1)}
                height={HEIGHT}
                fill="transparent"
                className={onSelect ? "cursor-pointer" : undefined}
                onMouseEnter={() => setHovered(i)}
                onClick={() => onSelect?.(p.point)}
              />
              {p.point.isPr && (
                <circle
                  cx={x(i)}
                  cy={y(p.value)}
                  r="5"
                  fill="var(--color-primary)"
                  opacity="0.22"
                />
              )}
              <circle
                cx={x(i)}
                cy={y(p.value)}
                r={isActive || isSelected ? 3.5 : 2}
                fill={
                  isActive || isSelected
                    ? "var(--color-primary)"
                    : "var(--color-surface)"
                }
                stroke="var(--color-primary)"
                strokeWidth="1.5"
                vectorEffect="non-scaling-stroke"
              />
            </g>
          );
        })}
      </svg>

      <div className="flex justify-between text-[10px] text-faint">
        <span>{formatDayLabel(plotted[0].point.date)}</span>
        <span>{plotted.length} sessions</span>
        <span>{formatDayLabel(plotted[plotted.length - 1].point.date)}</span>
      </div>
    </div>
  );
}

/** The metric switcher above the chart. */
export function MetricTabs({
  metric,
  onChange,
}: {
  metric: Metric;
  onChange: (metric: Metric) => void;
}) {
  return (
    <div className="flex gap-1">
      {(Object.keys(METRIC_LABELS) as Metric[]).map((key) => (
        <button
          key={key}
          type="button"
          onClick={() => onChange(key)}
          className={cn(
            "rounded-full px-2.5 py-1 text-xs font-medium transition-colors",
            metric === key
              ? "bg-surface-2 text-foreground"
              : "text-faint hover:text-foreground",
          )}
        >
          {METRIC_LABELS[key]}
        </button>
      ))}
    </div>
  );
}
