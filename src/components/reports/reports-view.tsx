"use client";

import { ChevronLeft, ChevronRight, Moon, X } from "lucide-react";
import { useMemo, useState } from "react";
import { DailyBarChart } from "@/components/reports/daily-bar-chart";
import { DonutChart } from "@/components/reports/donut-chart";
import { HabitGlyph } from "@/components/habits/habit-glyph";
import {
  computeRange,
  type RangeMode,
  rangeLabel,
  useReportsData,
} from "@/lib/client/use-reports";
import { useHabits, useHabitStats } from "@/lib/client/use-habits";
import { useSettings } from "@/lib/client/use-settings";
import { cn } from "@/lib/cn";
import { addDays } from "@/lib/habits";
import type { CategoryDTO, SleepDayStatsDTO } from "@/lib/types";
import { formatDuration, isoDateKey } from "@/lib/time";

const MODES: { value: RangeMode; label: string }[] = [
  { value: "week", label: "Week" },
  { value: "30d", label: "30 days" },
  { value: "90d", label: "90 days" },
];

interface Segment {
  catId: string;
  name: string;
  color: string;
  minutes: number;
  pct: number;
}

interface SleepRow {
  dayKey: string;
  label: string;
  stats: SleepDayStatsDTO;
}

function buildSegments(
  byCat: Record<string, number>,
  total: number,
  catMap: Map<string, CategoryDTO>,
): Segment[] {
  if (total <= 0) return [];
  return Object.entries(byCat)
    .map(([catId, minutes]) => ({
      catId,
      minutes,
      name: catId === "__none__" ? "Uncategorized" : (catMap.get(catId)?.name ?? catId),
      color: catId === "__none__" ? "#9aa0aa" : (catMap.get(catId)?.color ?? "#9aa0aa"),
      pct: (minutes / total) * 100,
    }))
    .sort((a, b) => b.minutes - a.minutes);
}

function eachDayKey(from: Date, to: Date): string[] {
  const keys: string[] = [];
  const d = new Date(from);
  while (d < to && keys.length < 366) {
    keys.push(isoDateKey(d));
    d.setDate(d.getDate() + 1);
  }
  return keys;
}

export function ReportsView() {
  const { settings } = useSettings();
  const [mode, setMode] = useState<RangeMode>("week");
  const [offset, setOffset] = useState(0);
  const [selectedDayKey, setSelectedDayKey] = useState<string | null>(null);

  const { from, to } = useMemo(
    () => computeRange(mode, offset, settings.weekStartsOn),
    [mode, offset, settings.weekStartsOn],
  );
  const { data, isLoading } = useReportsData(from, to);

  // Habits stats for the same range.
  const fromKey = isoDateKey(from);
  const toKey = addDays(isoDateKey(to), -1); // to is exclusive; stats API is inclusive
  const { habits: allHabits } = useHabits();
  const { stats: habitStats } = useHabitStats(fromKey, toKey);
  const habitMap = useMemo(
    () => new Map(allHabits.map((h) => [h.id, h])),
    [allHabits],
  );
  const activeHabitStats = useMemo(
    () => habitStats.filter((s) => s.scheduled > 0),
    [habitStats],
  );

  const catMap = useMemo(
    () => new Map(data.categories.map((c) => [c.id, c])),
    [data.categories],
  );

  const dayKeys = useMemo(() => eachDayKey(from, to), [from, to]);

  const dailyBars = useMemo(
    () =>
      dayKeys.map((key) => {
        const minutes = data.dailyTotals[key] ?? 0;
        const byCat = data.dailyByCategory[key] ?? {};
        const slices = Object.entries(byCat)
          .map(([catId, m]) => ({
            catId,
            minutes: m,
            color: catId === "__none__" ? "#9aa0aa" : (catMap.get(catId)?.color ?? "#9aa0aa"),
          }))
          .sort((a, b) => b.minutes - a.minutes);
        const d = new Date(`${key}T00:00:00`);
        const label =
          mode === "week"
            ? d.toLocaleDateString(undefined, { weekday: "short" })
            : d.toLocaleDateString(undefined, { month: "numeric", day: "numeric" });
        return { dayKey: key, label, minutes, slices };
      }),
    [dayKeys, data, catMap, mode],
  );

  const maxDayMinutes = useMemo(
    () => Math.max(1, ...dailyBars.map((d) => d.minutes)),
    [dailyBars],
  );

  const sleepRows = useMemo(
    () =>
      dayKeys
        .map((key) => {
          const d = new Date(`${key}T00:00:00`);
          const label =
            mode === "week"
              ? d.toLocaleDateString(undefined, { weekday: "short" })
              : d.toLocaleDateString(undefined, { month: "numeric", day: "numeric" });
          const stats = data.sleep.dailySleep[key];
          return stats ? { dayKey: key, label, stats } : null;
        })
        .filter((row): row is SleepRow => row !== null),
    [dayKeys, data.sleep.dailySleep, mode],
  );

  const maxSleepMinutes = useMemo(
    () => Math.max(1, ...sleepRows.map((d) => d.stats.totalMinutes)),
    [sleepRows],
  );

  // A selected day only counts if it's inside the visible range.
  const activeDayKey = selectedDayKey && dayKeys.includes(selectedDayKey) ? selectedDayKey : null;

  const rangeSegments = useMemo(
    () => buildSegments(data.totalsByCategory, data.totalMinutes, catMap),
    [data.totalsByCategory, data.totalMinutes, catMap],
  );

  const dayTotal = activeDayKey ? (data.dailyTotals[activeDayKey] ?? 0) : 0;
  const daySegments = useMemo(
    () =>
      activeDayKey
        ? buildSegments(data.dailyByCategory[activeDayKey] ?? {}, dayTotal, catMap)
        : [],
    [activeDayKey, data.dailyByCategory, dayTotal, catMap],
  );

  // Stat cards (over days that had tracked time).
  const activeDays = dailyBars.filter((d) => d.minutes > 0);
  const avgPerDay =
    activeDays.length > 0 ? data.totalMinutes / activeDays.length : 0;
  const bestDay = dailyBars.reduce(
    (best, d) => (d.minutes > best.minutes ? d : best),
    { dayKey: "", label: "—", minutes: 0 },
  );

  const resetLabel = mode === "week" ? "This week" : "Latest";
  const hasTrackedTime = data.totalMinutes > 0;
  const hasSleep = data.sleep.totalMinutes > 0;

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 md:px-8 md:py-8">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold tracking-tight">Reports</h1>
        <div className="inline-flex items-center gap-0.5 rounded-full border border-border bg-surface p-0.5">
          {MODES.map(({ value, label }) => (
            <button
              key={value}
              type="button"
              onClick={() => {
                setMode(value);
                setOffset(0);
                setSelectedDayKey(null);
              }}
              className={cn(
                "rounded-full px-3 py-1.5 text-xs font-medium transition-colors",
                mode === value ? "bg-surface-2 text-foreground" : "text-faint hover:text-muted",
              )}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* range navigation */}
      <div className="mt-4 flex items-center gap-1">
        <button
          type="button"
          aria-label="Previous period"
          onClick={() => setOffset((o) => o - 1)}
          className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>
        <button
          type="button"
          aria-label="Next period"
          onClick={() => setOffset((o) => Math.min(0, o + 1))}
          disabled={offset >= 0}
          className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-30"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
        <span className="ml-1 text-sm font-medium tabular-nums text-muted">
          {rangeLabel(from, to)}
        </span>
        {offset !== 0 && (
          <button
            type="button"
            onClick={() => setOffset(0)}
            className="ml-2 rounded-full border border-border px-2.5 py-1 text-xs font-medium text-muted hover:bg-surface-2"
          >
            {resetLabel}
          </button>
        )}
        <span className="ml-auto text-sm text-muted">
          {hasTrackedTime && (
            <>
              <span className="font-semibold tabular-nums text-foreground">
                {formatDuration(data.totalMinutes)}
              </span>{" "}
              tracked
            </>
          )}
          {hasTrackedTime && hasSleep ? " · " : ""}
          {hasSleep && (
            <>
              <span className="font-semibold tabular-nums text-foreground">
                {formatDuration(data.sleep.totalMinutes)}
              </span>{" "}
              sleep
            </>
          )}
        </span>
      </div>

      {isLoading ? (
        <div className="mt-8 space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-32 animate-pulse rounded-2xl bg-surface-2" />
          ))}
        </div>
      ) : !hasTrackedTime && !hasSleep ? (
        <p className="mt-24 text-center text-sm text-faint">
          No tracked time or sleep in this period yet.
        </p>
      ) : (
        <div className="mt-6 flex flex-col gap-6">
          {/* stat cards */}
          {hasTrackedTime && (
            <div className="grid grid-cols-3 gap-3">
              {[
                { label: "Total tracked", value: formatDuration(data.totalMinutes) },
                { label: "Daily average", value: formatDuration(avgPerDay) },
                {
                  label: "Best day",
                  value: bestDay.minutes > 0 ? formatDuration(bestDay.minutes) : "—",
                  sub: bestDay.minutes > 0 ? bestDay.label : undefined,
                },
              ].map(({ label, value, sub }) => (
                <div key={label} className="rounded-2xl border border-border bg-surface p-4">
                  <p className="text-xs text-faint">{label}</p>
                  <p className="mt-1 text-xl font-bold tabular-nums">{value}</p>
                  {sub && <p className="text-xs text-muted">{sub}</p>}
                </div>
              ))}
            </div>
          )}

          {/* daily activity bar chart */}
          {hasTrackedTime && (
            <div className="rounded-2xl border border-border bg-surface p-5">
              <div className="mb-4 flex items-center justify-between">
                <h2 className="text-sm font-semibold">Daily activity</h2>
                <span className="text-xs text-faint">Tap a day for its breakdown</span>
              </div>
              <DailyBarChart
                days={dailyBars}
                maxMinutes={maxDayMinutes}
                goalMinutes={settings.dailyGoalMinutes}
                selectedKey={activeDayKey}
                onSelect={(key) =>
                  setSelectedDayKey((prev) => (prev === key ? null : key))
                }
              />
            </div>
          )}

          {/* category breakdown — for the selected day, or the whole range */}
          {hasTrackedTime && (
            <div className="rounded-2xl border border-border bg-surface p-5">
              {activeDayKey ? (
                <DayBreakdownHeader dayKey={activeDayKey} total={dayTotal} onClear={() => setSelectedDayKey(null)} />
              ) : (
                <h2 className="mb-5 text-sm font-semibold">By category</h2>
              )}

              {activeDayKey ? (
                daySegments.length > 0 ? (
                  <DonutChart segments={daySegments} totalMinutes={dayTotal} />
                ) : (
                  <p className="py-6 text-center text-sm text-faint">
                    No tracked time on this day.
                  </p>
                )
              ) : rangeSegments.length > 0 ? (
                <DonutChart segments={rangeSegments} totalMinutes={data.totalMinutes} />
              ) : null}
            </div>
          )}

          {hasSleep && (
            <SleepPanel
              rows={sleepRows}
              maxMinutes={maxSleepMinutes}
              averageMinutes={data.sleep.averageMinutes}
              bestDay={data.sleep.bestDay}
            />
          )}

          {/* habits completion */}
          {activeHabitStats.length > 0 && (
            <div className="rounded-2xl border border-border bg-surface p-5">
              <h2 className="mb-4 text-sm font-semibold">Habits</h2>
              <div className="flex flex-col gap-3">
                {activeHabitStats.map((stat) => {
                  const habit = habitMap.get(stat.habitId);
                  if (!habit) return null;
                  const pct = stat.scheduled > 0 ? stat.completed / stat.scheduled : 0;
                  return (
                    <div key={stat.habitId} className="flex items-center gap-3">
                      <span
                        className="grid h-7 w-7 shrink-0 place-items-center rounded-lg"
                        style={{ backgroundColor: `${habit.color}22`, color: habit.color }}
                      >
                        <HabitGlyph name={habit.icon} className="h-3.5 w-3.5" />
                      </span>
                      <div className="min-w-0 flex-1">
                        <div className="mb-1.5 flex items-center justify-between gap-2">
                          <span className="truncate text-sm font-medium">{habit.name}</span>
                          <span className="shrink-0 text-xs tabular-nums text-faint">
                            {stat.completed}/{stat.scheduled}
                          </span>
                        </div>
                        <div className="h-1.5 overflow-hidden rounded-full bg-surface-2">
                          <div
                            className="h-full rounded-full transition-all duration-500"
                            style={{ width: `${pct * 100}%`, backgroundColor: habit.color }}
                          />
                        </div>
                      </div>
                      {stat.streak > 1 && (
                        <span
                          className="shrink-0 rounded-full px-2 py-0.5 text-xs font-semibold tabular-nums"
                          style={{ backgroundColor: `${habit.color}22`, color: habit.color }}
                        >
                          {stat.streak}d
                        </span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function DayBreakdownHeader({
  dayKey,
  total,
  onClear,
}: {
  dayKey: string;
  total: number;
  onClear: () => void;
}) {
  const label = new Date(`${dayKey}T00:00:00`).toLocaleDateString(undefined, {
    weekday: "long",
    month: "short",
    day: "numeric",
  });
  return (
    <div className="mb-5 flex items-center justify-between gap-2">
      <div>
        <h2 className="text-sm font-semibold">{label}</h2>
        <p className="text-xs text-faint tabular-nums">{formatDuration(total)} tracked</p>
      </div>
      <button
        type="button"
        onClick={onClear}
        className="inline-flex items-center gap-1 rounded-full border border-border px-2.5 py-1 text-xs font-medium text-muted hover:bg-surface-2"
      >
        <X className="h-3 w-3" />
        Whole range
      </button>
    </div>
  );
}

function SleepPanel({
  rows,
  maxMinutes,
  averageMinutes,
  bestDay,
}: {
  rows: SleepRow[];
  maxMinutes: number;
  averageMinutes: number;
  bestDay: { dayKey: string; minutes: number } | null;
}) {
  const bestLabel = bestDay
    ? new Date(`${bestDay.dayKey}T00:00:00`).toLocaleDateString(undefined, {
        weekday: "short",
        month: "short",
        day: "numeric",
      })
    : null;

  return (
    <div className="rounded-2xl border border-border bg-surface p-5">
      <div className="mb-4 flex items-center gap-2">
        <span className="grid h-7 w-7 place-items-center rounded-lg bg-surface-2 text-muted">
          <Moon className="h-3.5 w-3.5" />
        </span>
        <h2 className="text-sm font-semibold">Sleep</h2>
      </div>

      <div className="grid grid-cols-3 gap-4 border-b border-border pb-4">
        <div>
          <p className="text-xs text-faint">Average</p>
          <p className="mt-1 text-lg font-bold tabular-nums">
            {formatDuration(averageMinutes)}
          </p>
        </div>
        <div>
          <p className="text-xs text-faint">Best night</p>
          <p className="mt-1 text-lg font-bold tabular-nums">
            {bestDay ? formatDuration(bestDay.minutes) : "—"}
          </p>
          {bestLabel && <p className="text-xs text-muted">{bestLabel}</p>}
        </div>
        <div>
          <p className="text-xs text-faint">Logged nights</p>
          <p className="mt-1 text-lg font-bold tabular-nums">{rows.length}</p>
        </div>
      </div>

      <div className="mt-4 flex flex-col gap-3">
        {rows.map((row) => (
          <SleepRowBar key={row.dayKey} row={row} maxMinutes={maxMinutes} />
        ))}
      </div>
    </div>
  );
}

function SleepRowBar({ row, maxMinutes }: { row: SleepRow; maxMinutes: number }) {
  const { stats } = row;
  const width = Math.max(6, (stats.totalMinutes / maxMinutes) * 100);
  const stageTotal = stats.lightMinutes + stats.deepMinutes + stats.remMinutes + stats.awakeMinutes;
  const unknownMinutes = Math.max(0, stats.totalMinutes - stageTotal);
  const segments = [
    { key: "deep", minutes: stats.deepMinutes, color: "#6366f1" },
    { key: "rem", minutes: stats.remMinutes, color: "#ec4899" },
    { key: "light", minutes: stats.lightMinutes, color: "#38bdf8" },
    { key: "awake", minutes: stats.awakeMinutes, color: "#f59e0b" },
    { key: "sleep", minutes: unknownMinutes, color: "#8b9aaa" },
  ].filter((segment) => segment.minutes > 0);

  return (
    <div className="grid grid-cols-[3.5rem_1fr_4.5rem] items-center gap-3">
      <span className="text-xs font-medium text-muted">{row.label}</span>
      <div className="h-3 overflow-hidden rounded-full bg-surface-2">
        <div className="flex h-full overflow-hidden rounded-full" style={{ width: `${width}%` }}>
          {segments.length > 0 ? (
            segments.map((segment) => (
              <span
                key={segment.key}
                className="h-full"
                style={{
                  width: `${(segment.minutes / Math.max(1, stats.totalMinutes)) * 100}%`,
                  backgroundColor: segment.color,
                }}
              />
            ))
          ) : (
            <span className="h-full w-full bg-muted" />
          )}
        </div>
      </div>
      <span className="text-right text-xs tabular-nums text-faint">
        {formatDuration(stats.totalMinutes)}
      </span>
    </div>
  );
}
