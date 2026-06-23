"use client";

import { Flame } from "lucide-react";
import { useHabitStats } from "@/lib/client/use-habits";
import { useSettings } from "@/lib/client/use-settings";
import { addDays } from "@/lib/habits";
import { isoDateKey, startOfViewDay } from "@/lib/time";
import type { HabitDTO } from "@/lib/types";
import { HabitGlyph } from "./habit-glyph";

const WINDOW_DAYS = 28;

export function HabitInsights({ habits }: { habits: HabitDTO[] }) {
  const { settings } = useSettings();
  const todayKey = isoDateKey(startOfViewDay(new Date(), settings.dayStartHour));
  const fromKey = addDays(todayKey, -(WINDOW_DAYS - 1));
  const { byHabit, isLoading } = useHabitStats(fromKey, todayKey);

  if (habits.length === 0) {
    return (
      <p className="rounded-2xl border border-dashed border-border py-10 text-center text-sm text-faint">
        No habits to analyze yet.
      </p>
    );
  }

  if (isLoading) {
    return (
      <div className="flex flex-col gap-2">
        {[0, 1, 2].map((i) => (
          <div key={i} className="h-20 animate-pulse rounded-2xl bg-surface-2" />
        ))}
      </div>
    );
  }

  const days = Array.from({ length: WINDOW_DAYS }, (_, i) => addDays(fromKey, i));

  return (
    <div className="flex flex-col gap-2">
      {habits.map((h) => {
        const stat = byHabit.get(h.id);
        const fractions = stat?.fractions ?? {};
        const pct =
          stat && stat.scheduled > 0
            ? Math.round((stat.completed / stat.scheduled) * 100)
            : 0;
        return (
          <div key={h.id} className="rounded-2xl border border-border bg-surface p-3.5">
            <div className="flex items-center gap-3">
              <span
                className="grid h-9 w-9 shrink-0 place-items-center rounded-xl"
                style={{ backgroundColor: `${h.color}22`, color: h.color }}
              >
                <HabitGlyph name={h.icon} className="h-[18px] w-[18px]" />
              </span>
              <span className="min-w-0 flex-1 truncate text-sm font-semibold">
                {h.name}
              </span>
              <span
                className="inline-flex items-center gap-1 text-sm font-semibold tabular-nums"
                title="Current streak"
                style={{ color: stat && stat.streak > 0 ? h.color : undefined }}
              >
                <Flame className="h-4 w-4" />
                {stat?.streak ?? 0}
              </span>
            </div>

            <div className="mt-3 flex items-center gap-3">
              <div className="flex flex-1 flex-wrap gap-0.5">
                {days.map((d) => {
                  const f = fractions[d];
                  const scheduled = f !== undefined;
                  return (
                    <span
                      key={d}
                      title={`${d}${scheduled ? ` · ${Math.round(f * 100)}%` : ""}`}
                      className="h-3 w-3 rounded-[3px]"
                      style={
                        scheduled
                          ? { backgroundColor: h.color, opacity: 0.2 + 0.8 * Math.min(1, f) }
                          : { backgroundColor: "var(--surface-2)" }
                      }
                    />
                  );
                })}
              </div>
            </div>

            <div className="mt-2.5 flex items-center gap-4 text-xs text-faint">
              <span>
                <span className="font-medium text-muted">{pct}%</span> done · last{" "}
                {WINDOW_DAYS}d
              </span>
              <span>
                Best streak{" "}
                <span className="font-medium text-muted">{stat?.bestStreak ?? 0}</span>
              </span>
            </div>
          </div>
        );
      })}
    </div>
  );
}
