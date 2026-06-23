"use client";

import { useMemo, useState } from "react";
import { DailyBarChart } from "@/components/reports/daily-bar-chart";
import { DonutChart } from "@/components/reports/donut-chart";
import { type RangePreset, useReports } from "@/lib/client/use-reports";
import { useSettings } from "@/lib/client/use-settings";
import { cn } from "@/lib/cn";
import { formatDuration } from "@/lib/time";

const PRESETS: { value: RangePreset; label: string }[] = [
  { value: "7d", label: "7 days" },
  { value: "30d", label: "30 days" },
  { value: "90d", label: "90 days" },
];

export function ReportsView() {
  const [preset, setPreset] = useState<RangePreset>("30d");
  const { data, isLoading } = useReports(preset);
  const { settings } = useSettings();

  const catMap = new Map(data.categories.map((c) => [c.id, c]));

  const segments = useMemo(() => {
    if (data.totalMinutes === 0) return [];
    return Object.entries(data.totalsByCategory)
      .map(([catId, minutes]) => ({
        catId,
        minutes,
        name: catId === "__none__" ? "Uncategorized" : (catMap.get(catId)?.name ?? catId),
        color: catId === "__none__" ? "#9aa0aa" : (catMap.get(catId)?.color ?? "#9aa0aa"),
        pct: (minutes / data.totalMinutes) * 100,
      }))
      .sort((a, b) => b.minutes - a.minutes);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data]);

  const dailyBars = useMemo(() => {
    return Object.entries(data.dailyTotals)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([dayKey, minutes]) => {
        const d = new Date(dayKey + "T00:00:00");
        const label = d.toLocaleDateString(undefined, {
          month: "numeric",
          day: "numeric",
        });
        const bycat = data.dailyByCategory[dayKey] ?? {};
        const slices = Object.entries(bycat)
          .map(([catId, catMinutes]) => ({
            catId,
            minutes: catMinutes,
            color: catId === "__none__" ? "#9aa0aa" : (catMap.get(catId)?.color ?? "#9aa0aa"),
          }))
          .sort((a, b) => b.minutes - a.minutes);
        return { dayKey, label, minutes, slices };
      });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data]);

  const maxDayMinutes = useMemo(
    () => Math.max(1, ...dailyBars.map((d) => d.minutes)),
    [dailyBars],
  );

  // Stat cards
  const avgPerDay = dailyBars.length > 0 ? data.totalMinutes / dailyBars.length : 0;
  const bestDay = dailyBars.reduce(
    (best, d) => (d.minutes > best.minutes ? d : best),
    { dayKey: "", label: "—", minutes: 0 },
  );

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 md:px-8 md:py-8">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold tracking-tight">Reports</h1>

        {/* range picker */}
        <div className="inline-flex items-center gap-0.5 rounded-full border border-border bg-surface p-0.5">
          {PRESETS.map(({ value, label }) => (
            <button
              key={value}
              type="button"
              onClick={() => setPreset(value)}
              className={cn(
                "rounded-full px-3 py-1.5 text-xs font-medium transition-colors",
                preset === value
                  ? "bg-surface-2 text-foreground"
                  : "text-faint hover:text-muted",
              )}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {isLoading ? (
        <div className="mt-8 space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-32 animate-pulse rounded-2xl bg-surface-2" />
          ))}
        </div>
      ) : data.totalMinutes === 0 ? (
        <p className="mt-24 text-center text-sm text-faint">
          No tracked time in this period yet.
        </p>
      ) : (
        <div className="mt-6 flex flex-col gap-6">
          {/* stat cards */}
          <div className="grid grid-cols-3 gap-3">
            {[
              { label: "Total tracked", value: formatDuration(data.totalMinutes) },
              { label: "Daily average", value: formatDuration(avgPerDay) },
              {
                label: "Best day",
                value: bestDay.minutes > 0
                  ? `${formatDuration(bestDay.minutes)}`
                  : "—",
                sub: bestDay.label !== "—" ? bestDay.label : undefined,
              },
            ].map(({ label, value, sub }) => (
              <div key={label} className="rounded-2xl border border-border bg-surface p-4">
                <p className="text-xs text-faint">{label}</p>
                <p className="mt-1 text-xl font-bold tabular-nums">{value}</p>
                {sub && <p className="text-xs text-muted">{sub}</p>}
              </div>
            ))}
          </div>

          {/* daily activity bar chart */}
          <div className="rounded-2xl border border-border bg-surface p-5">
            <h2 className="mb-4 text-sm font-semibold">Daily activity</h2>
            <DailyBarChart
              days={dailyBars}
              maxMinutes={maxDayMinutes}
              goalMinutes={settings.dailyGoalMinutes}
            />
          </div>

          {/* donut breakdown */}
          {segments.length > 0 && (
            <div className="rounded-2xl border border-border bg-surface p-5">
              <h2 className="mb-5 text-sm font-semibold">By category</h2>
              <DonutChart segments={segments} totalMinutes={data.totalMinutes} />
            </div>
          )}
        </div>
      )}
    </div>
  );
}
