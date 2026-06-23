"use client";

import { CalendarCheck, ChevronLeft, ChevronRight, Plus, Sparkles } from "lucide-react";
import { useMemo, useState } from "react";
import { useHabitDay, useHabits, useHabitStats } from "@/lib/client/use-habits";
import { useSettings } from "@/lib/client/use-settings";
import { startOfWeek } from "@/lib/client/use-week";
import { cn } from "@/lib/cn";
import { addDays, parseDateKey } from "@/lib/habits";
import { isoDateKey, startOfViewDay } from "@/lib/time";
import type { HabitDTO } from "@/lib/types";
import { HabitCard } from "./habit-card";
import { HabitForm } from "./habit-form";
import { HabitInsights } from "./habit-insights";

const WEEKDAY = ["S", "M", "T", "W", "T", "F", "S"];

export function HabitsView() {
  const { settings } = useSettings();
  const { dayStartHour, weekStartsOn } = settings;

  const todayKey = isoDateKey(startOfViewDay(new Date(), dayStartHour));
  const [selectedKey, setSelectedKey] = useState(todayKey);
  const [tab, setTab] = useState<"day" | "insights">("day");
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<HabitDTO | null>(null);

  const selectedDate = parseDateKey(selectedKey);
  const { habits: dayHabits, isLoading, act } = useHabitDay(selectedDate);
  const { habits: allHabits } = useHabits();

  const weekDates = useMemo(() => {
    const start = startOfWeek(parseDateKey(selectedKey), weekStartsOn);
    return Array.from({ length: 7 }, (_, i) => {
      const d = new Date(start);
      d.setDate(d.getDate() + i);
      return d;
    });
  }, [selectedKey, weekStartsOn]);

  const weekFrom = isoDateKey(weekDates[0]);
  const weekTo = isoDateKey(weekDates[6]);
  const { byHabit } = useHabitStats(weekFrom, weekTo);

  function dotsForDay(key: string) {
    const dots: { color: string; done: boolean }[] = [];
    for (const h of allHabits) {
      const f = byHabit.get(h.id)?.fractions[key];
      if (f === undefined) continue;
      dots.push({ color: h.color, done: f >= 1 });
    }
    return dots;
  }

  function openCreate() {
    setEditing(null);
    setFormOpen(true);
  }
  function openEdit(habit: HabitDTO) {
    setEditing(habit);
    setFormOpen(true);
  }

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 md:px-8 md:py-7">
      {/* header */}
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold tracking-tight">Habits</h1>
        <div className="flex items-center gap-2">
          <div className="inline-flex rounded-full border border-border bg-surface p-0.5 text-xs font-medium">
            {(["day", "insights"] as const).map((t) => (
              <button
                key={t}
                type="button"
                onClick={() => setTab(t)}
                className={cn(
                  "rounded-full px-3 py-1 capitalize transition-colors",
                  tab === t ? "bg-surface-2 text-foreground" : "text-faint hover:text-muted",
                )}
              >
                {t}
              </button>
            ))}
          </div>
          <button
            type="button"
            onClick={openCreate}
            aria-label="New habit"
            className="grid h-9 w-9 place-items-center rounded-full bg-primary text-primary-foreground shadow-sm transition-colors hover:bg-primary-hover"
          >
            <Plus className="h-4.5 w-4.5" />
          </button>
        </div>
      </div>

      {/* week strip */}
      <div className="mt-4 flex items-center gap-1">
        <button
          type="button"
          aria-label="Previous week"
          onClick={() => setSelectedKey((k) => addDays(k, -7))}
          className="grid h-8 w-7 shrink-0 place-items-center rounded-lg text-faint hover:bg-surface-2 hover:text-foreground"
        >
          <ChevronLeft className="h-4 w-4" />
        </button>

        <div className="grid flex-1 grid-cols-7 gap-1">
          {weekDates.map((d) => {
            const key = isoDateKey(d);
            const selected = key === selectedKey;
            const isToday = key === todayKey;
            const dots = dotsForDay(key);
            return (
              <button
                key={key}
                type="button"
                onClick={() => setSelectedKey(key)}
                className={cn(
                  "flex flex-col items-center gap-1 rounded-xl py-1.5 transition-colors",
                  selected ? "bg-surface-2" : "hover:bg-surface-2/60",
                )}
              >
                <span className="text-[10px] font-medium uppercase text-faint">
                  {WEEKDAY[d.getDay()]}
                </span>
                <span
                  className={cn(
                    "grid h-7 w-7 place-items-center rounded-full text-sm font-semibold tabular-nums",
                    isToday && !selected && "text-primary",
                    selected && "bg-primary text-primary-foreground",
                  )}
                >
                  {d.getDate()}
                </span>
                <span className="flex h-1.5 items-center gap-0.5">
                  {dots.slice(0, 4).map((dot, i) => (
                    <span
                      key={i}
                      className="h-1 w-1 rounded-full"
                      style={{
                        backgroundColor: dot.done ? dot.color : "var(--border-strong)",
                      }}
                    />
                  ))}
                </span>
              </button>
            );
          })}
        </div>

        <button
          type="button"
          aria-label="Next week"
          onClick={() => setSelectedKey((k) => addDays(k, 7))}
          className="grid h-8 w-7 shrink-0 place-items-center rounded-lg text-faint hover:bg-surface-2 hover:text-foreground"
        >
          <ChevronRight className="h-4 w-4" />
        </button>
      </div>

      {/* body */}
      <div className="mt-5">
        {tab === "insights" ? (
          <HabitInsights habits={allHabits} />
        ) : isLoading && dayHabits.length === 0 ? (
          <div className="flex flex-col gap-2">
            {[0, 1, 2].map((i) => (
              <div key={i} className="h-[68px] animate-pulse rounded-2xl bg-surface-2" />
            ))}
          </div>
        ) : allHabits.length === 0 ? (
          <EmptyState onCreate={openCreate} />
        ) : dayHabits.length === 0 ? (
          <div className="flex flex-col items-center gap-2 rounded-2xl border border-dashed border-border py-12 text-center">
            <CalendarCheck className="h-6 w-6 text-faint" />
            <p className="text-sm text-muted">Nothing scheduled for this day.</p>
          </div>
        ) : (
          <div className="flex flex-col gap-2">
            {dayHabits.map((h) => (
              <HabitCard key={h.id} habit={h} act={act} onEdit={() => openEdit(h)} />
            ))}
          </div>
        )}
      </div>

      <HabitForm
        open={formOpen}
        habit={editing}
        defaultDate={selectedKey}
        onClose={() => setFormOpen(false)}
      />
    </div>
  );
}

function EmptyState({ onCreate }: { onCreate: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border py-14 text-center">
      <span className="grid h-12 w-12 place-items-center rounded-2xl bg-primary/10 text-primary">
        <Sparkles className="h-6 w-6" />
      </span>
      <div>
        <p className="text-sm font-medium">No habits yet</p>
        <p className="mt-0.5 text-xs text-faint">
          Build a routine — tasks, counts, or timed goals.
        </p>
      </div>
      <button
        type="button"
        onClick={onCreate}
        className="mt-1 inline-flex items-center gap-1.5 rounded-full bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary-hover"
      >
        <Plus className="h-4 w-4" />
        New habit
      </button>
    </div>
  );
}
