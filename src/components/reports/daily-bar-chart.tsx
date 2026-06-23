"use client";

import { formatDuration } from "@/lib/time";

interface CategorySlice {
  catId: string;
  minutes: number;
  color: string;
}

export interface DayBar {
  dayKey: string;
  label: string;
  minutes: number;
  slices: CategorySlice[]; // ordered largest-first so the tallest is at bottom
}

const BAR_MAX_PX = 180;

export function DailyBarChart({
  days,
  maxMinutes,
  goalMinutes = 8 * 60,
}: {
  days: DayBar[];
  maxMinutes: number;
  goalMinutes?: number;
}) {
  return (
    <div className="flex flex-col gap-2">
      <div className="relative flex items-end gap-1 overflow-x-auto pb-5">
        {/* daily-goal reference line */}
        {maxMinutes > 0 && goalMinutes > 0 && goalMinutes <= maxMinutes && (
          <div
            className="pointer-events-none absolute inset-x-0 border-t border-dashed border-border"
            style={{
              bottom: `calc(20px + ${(goalMinutes / maxMinutes) * BAR_MAX_PX}px)`,
            }}
          >
            <span className="absolute right-0 -translate-y-full pr-1 text-[10px] text-faint">
              {Math.round((goalMinutes / 60) * 10) / 10}h
            </span>
          </div>
        )}

        {days.map((d) => {
          const totalPx = maxMinutes > 0
            ? Math.max(d.minutes > 0 ? 3 : 1, (d.minutes / maxMinutes) * BAR_MAX_PX)
            : 1;

          return (
            <div
              key={d.dayKey}
              className="group flex min-w-[28px] flex-1 flex-col items-center gap-1"
            >
              {/* tooltip */}
              <span className="invisible whitespace-nowrap rounded bg-foreground px-1.5 py-0.5 text-[10px] text-background opacity-0 transition-opacity group-hover:visible group-hover:opacity-100">
                {formatDuration(d.minutes)}
              </span>

              {/* stacked bar */}
              <div
                className="relative w-full overflow-hidden rounded-t-sm"
                style={{ height: totalPx, opacity: d.minutes > 0 ? 1 : 0.18 }}
              >
                {d.slices.length > 0 ? (
                  d.slices.map((s) => (
                    <div
                      key={s.catId}
                      className="w-full transition-all duration-300"
                      style={{
                        height: `${(s.minutes / d.minutes) * 100}%`,
                        backgroundColor: s.color,
                      }}
                    />
                  ))
                ) : (
                  <div className="h-full w-full bg-primary/30" />
                )}
              </div>

              <span className="text-[10px] text-faint">{d.label}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
