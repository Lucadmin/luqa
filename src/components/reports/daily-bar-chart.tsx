"use client";

import { formatDuration } from "@/lib/time";

interface DayBar {
  dayKey: string; // "2025-06-10"
  label: string; // "Mon 10"
  minutes: number;
}

export function DailyBarChart({
  days,
  maxMinutes,
}: {
  days: DayBar[];
  maxMinutes: number;
}) {
  const goal = 8 * 60; // 8-hour reference line

  return (
    <div className="flex flex-col gap-2">
      <div className="relative flex items-end gap-1.5 overflow-x-auto pb-5">
        {/* 8-hour reference line */}
        {maxMinutes > 0 && (
          <div
            className="pointer-events-none absolute inset-x-0 border-t border-dashed border-border-strong"
            style={{ bottom: `calc(20px + ${(Math.min(goal, maxMinutes) / maxMinutes) * 180}px)` }}
          >
            <span className="absolute right-0 -translate-y-full pr-1 text-[10px] text-faint">
              8h
            </span>
          </div>
        )}

        {days.map((d) => {
          const h = maxMinutes > 0 ? Math.max(2, (d.minutes / maxMinutes) * 180) : 2;
          return (
            <div key={d.dayKey} className="group flex min-w-[28px] flex-1 flex-col items-center gap-1">
              {/* tooltip */}
              <span className="invisible whitespace-nowrap rounded bg-foreground px-1.5 py-0.5 text-[10px] text-background opacity-0 transition-opacity group-hover:visible group-hover:opacity-100">
                {formatDuration(d.minutes)}
              </span>
              <div
                className="w-full rounded-t-sm bg-primary/70 transition-all duration-300 group-hover:bg-primary"
                style={{ height: d.minutes > 0 ? h : 2, opacity: d.minutes > 0 ? 1 : 0.15 }}
              />
              <span className="text-[10px] text-faint">{d.label}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
