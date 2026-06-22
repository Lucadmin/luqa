"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useMemo, useState } from "react";
import { startOfWeekMonday, useWeek } from "@/lib/client/use-week";
import { formatDuration, isoDateKey } from "@/lib/time";
import type { CategoryDTO, TimeEntryDTO } from "@/lib/types";

const DAY_LABELS = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

function addWeeks(d: Date, n: number) {
  const c = new Date(d);
  c.setDate(c.getDate() + n * 7);
  return c;
}

function weekLabel(start: Date): string {
  const end = new Date(start);
  end.setDate(end.getDate() + 6);
  const opts: Intl.DateTimeFormatOptions = { month: "short", day: "numeric" };
  return `${start.toLocaleDateString(undefined, opts)} – ${end.toLocaleDateString(undefined, opts)}`;
}

function minutesForDay(
  entries: TimeEntryDTO[],
  dayKey: string,
): number {
  return entries.reduce((sum, e) => {
    if (!e.endTime) return sum;
    if (isoDateKey(new Date(e.startTime)) !== dayKey) return sum;
    return sum + (Date.parse(e.endTime) - Date.parse(e.startTime)) / 60000;
  }, 0);
}

function minutesByCategoryForDay(
  entries: TimeEntryDTO[],
  dayKey: string,
): Record<string, number> {
  const map: Record<string, number> = {};
  for (const e of entries) {
    if (!e.endTime) continue;
    if (isoDateKey(new Date(e.startTime)) !== dayKey) continue;
    const mins = (Date.parse(e.endTime) - Date.parse(e.startTime)) / 60000;
    const key = e.categoryId ?? "__none__";
    map[key] = (map[key] ?? 0) + mins;
  }
  return map;
}

function DayColumn({
  label,
  date,
  entries,
  categories,
  maxMinutes,
  isToday,
}: {
  label: string;
  date: Date;
  entries: TimeEntryDTO[];
  categories: CategoryDTO[];
  maxMinutes: number;
  isToday: boolean;
}) {
  const dayKey = isoDateKey(date);
  const totalMins = minutesForDay(entries, dayKey);
  const byCategory = minutesByCategoryForDay(entries, dayKey);
  const catMap = new Map(categories.map((c) => [c.id, c]));

  const segments = Object.entries(byCategory)
    .map(([catId, mins]) => ({
      catId,
      mins,
      color: catId === "__none__" ? "#9aa0aa" : (catMap.get(catId)?.color ?? "#9aa0aa"),
      name: catId === "__none__" ? "Uncategorized" : (catMap.get(catId)?.name ?? catId),
    }))
    .sort((a, b) => b.mins - a.mins);

  const barPct = maxMinutes > 0 ? (totalMins / maxMinutes) * 100 : 0;

  return (
    <div className="flex flex-col items-center gap-2">
      <span
        className={`text-xs font-medium ${
          isToday ? "text-primary" : "text-faint"
        }`}
      >
        {label}
      </span>
      <span
        className={`text-[11px] tabular-nums ${
          isToday ? "text-primary font-semibold" : "text-faint"
        }`}
      >
        {date.getDate()}
      </span>

      {/* stacked bar */}
      <div className="relative w-full flex-1 overflow-hidden rounded-lg bg-surface-2">
        <div
          className="absolute bottom-0 left-0 right-0 flex flex-col-reverse overflow-hidden rounded-lg transition-all duration-500"
          style={{ height: `${barPct}%` }}
        >
          {segments.map((seg, i) => (
            <div
              key={seg.catId}
              className="w-full"
              style={{
                height: `${(seg.mins / totalMins) * 100}%`,
                backgroundColor: seg.color,
                opacity: i === 0 ? 1 : 0.75,
              }}
              title={`${seg.name}: ${formatDuration(seg.mins)}`}
            />
          ))}
        </div>
      </div>

      <span className="text-[11px] font-medium tabular-nums text-muted">
        {totalMins > 0 ? formatDuration(totalMins) : "—"}
      </span>
    </div>
  );
}

export function WeekView() {
  const [weekStart, setWeekStart] = useState(() =>
    startOfWeekMonday(new Date()),
  );
  const { data, isLoading } = useWeek(weekStart);
  const todayKey = isoDateKey(new Date());

  const days = useMemo(() =>
    Array.from({ length: 7 }, (_, i) => {
      const d = new Date(weekStart);
      d.setDate(d.getDate() + i);
      return d;
    }),
  [weekStart]);

  const maxDayMinutes = useMemo(() => {
    return Math.max(
      1,
      ...days.map((d) => minutesForDay(data.entries, isoDateKey(d))),
    );
  }, [data.entries, days]);

  const isThisWeek =
    isoDateKey(weekStart) === isoDateKey(startOfWeekMonday(new Date()));

  // Category breakdown for the whole week.
  const catMap = new Map(data.categories.map((c) => [c.id, c]));
  const weekBreakdown = Object.entries(data.totalsByCategory)
    .map(([catId, mins]) => ({
      catId,
      mins,
      color: catId === "__none__" ? "#9aa0aa" : (catMap.get(catId)?.color ?? "#9aa0aa"),
      name: catId === "__none__" ? "Uncategorized" : (catMap.get(catId)?.name ?? catId),
    }))
    .sort((a, b) => b.mins - a.mins);

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 md:px-8 md:py-8">
      {/* header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-1">
          <button
            type="button"
            aria-label="Previous week"
            onClick={() => setWeekStart((w) => addWeeks(w, -1))}
            className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
          >
            <ChevronLeft className="h-4 w-4" />
          </button>
          <h1 className="min-w-[12rem] text-center text-base font-semibold">
            {weekLabel(weekStart)}
          </h1>
          <button
            type="button"
            aria-label="Next week"
            onClick={() => setWeekStart((w) => addWeeks(w, 1))}
            className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
          >
            <ChevronRight className="h-4 w-4" />
          </button>
          {!isThisWeek && (
            <button
              type="button"
              onClick={() => setWeekStart(startOfWeekMonday(new Date()))}
              className="ml-2 rounded-full border border-border px-2.5 py-1 text-xs font-medium text-muted hover:bg-surface-2"
            >
              This week
            </button>
          )}
        </div>
        <span className="text-sm text-muted">
          <span className="font-semibold text-foreground tabular-nums">
            {formatDuration(data.totalMinutes)}
          </span>{" "}
          this week
        </span>
      </div>

      {isLoading ? (
        <div className="mt-8 grid grid-cols-7 gap-2 md:gap-3">
          {Array.from({ length: 7 }).map((_, i) => (
            <div
              key={i}
              className="h-64 animate-pulse rounded-xl bg-surface-2"
            />
          ))}
        </div>
      ) : (
        <>
          {/* bar chart */}
          <div className="mt-6 grid h-72 grid-cols-7 gap-2 md:gap-3">
            {days.map((d, i) => (
              <DayColumn
                key={isoDateKey(d)}
                label={DAY_LABELS[i]}
                date={d}
                entries={data.entries}
                categories={data.categories}
                maxMinutes={maxDayMinutes}
                isToday={isoDateKey(d) === todayKey}
              />
            ))}
          </div>

          {/* category legend + totals */}
          {weekBreakdown.length > 0 && (
            <div className="mt-8 flex flex-col gap-2">
              <h2 className="text-sm font-medium text-faint">By category</h2>
              <div className="flex flex-col gap-1.5">
                {weekBreakdown.map((item) => {
                  const pct = data.totalMinutes > 0
                    ? (item.mins / data.totalMinutes) * 100
                    : 0;
                  return (
                    <div key={item.catId} className="flex items-center gap-3">
                      <span
                        className="h-2.5 w-2.5 shrink-0 rounded-full"
                        style={{ backgroundColor: item.color }}
                      />
                      <span className="min-w-0 flex-1 truncate text-sm">
                        {item.name}
                      </span>
                      <span className="text-sm tabular-nums text-muted">
                        {formatDuration(item.mins)}
                      </span>
                      <div className="w-24 overflow-hidden rounded-full bg-surface-2">
                        <div
                          className="h-1.5 rounded-full transition-all duration-500"
                          style={{
                            width: `${pct}%`,
                            backgroundColor: item.color,
                          }}
                        />
                      </div>
                      <span className="w-9 text-right text-xs tabular-nums text-faint">
                        {Math.round(pct)}%
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>
          )}

          {data.entries.length === 0 && (
            <p className="mt-16 text-center text-sm text-faint">
              No entries tracked this week yet.
            </p>
          )}
        </>
      )}
    </div>
  );
}
