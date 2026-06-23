"use client";

import type { HabitAction } from "@/lib/client/use-habits";
import { useHabitProgress } from "@/lib/client/use-habit-progress";
import { cn } from "@/lib/cn";
import { goalPeriodLabel, scheduleSummary } from "@/lib/habits";
import { formatHMS } from "@/lib/time";
import type { HabitDayDTO } from "@/lib/types";
import { HabitControl } from "./habit-control";
import { HabitGlyph } from "./habit-glyph";

function periodWord(t: HabitDayDTO["scheduleType"]): string {
  if (t === "TIMES_PER_WEEK") return "this week";
  if (t === "TIMES_PER_MONTH") return "this month";
  if (t === "TIMES_PER_YEAR") return "this year";
  return "";
}

export function HabitCard({
  habit,
  act,
  onEdit,
}: {
  habit: HabitDayDTO;
  act: (id: string, action: HabitAction, value?: number) => Promise<unknown>;
  onEdit: (habit: HabitDayDTO) => void;
}) {
  const progress = useHabitProgress(habit);

  const parts: string[] = [];
  if (habit.goalType === "TIME") {
    const periodLabel = goalPeriodLabel(habit.goalPeriod);
    const suffix = periodLabel ? ` ${periodLabel}` : "";
    parts.push(`${formatHMS(progress.liveSeconds)} / ${formatHMS(habit.targetSeconds)}${suffix}`);
  } else if (habit.goalType === "COUNT") {
    parts.push(`${habit.count} / ${habit.targetCount}`);
  }
  if (habit.periodTarget != null) {
    parts.push(`${habit.periodDone ?? 0}/${habit.periodTarget} ${periodWord(habit.scheduleType)}`);
  } else {
    parts.push(scheduleSummary(habit));
  }

  return (
    <div
      className={cn(
        "group flex items-center gap-3 rounded-2xl border bg-surface px-3.5 py-3 transition-colors",
        progress.done ? "border-border/60" : "border-border",
      )}
    >
      <button
        type="button"
        onClick={() => onEdit(habit)}
        className={cn(
          "flex min-w-0 flex-1 items-center gap-3 text-left",
          progress.done && "opacity-65",
        )}
      >
        <span
          className="grid h-11 w-11 shrink-0 place-items-center rounded-xl"
          style={{ backgroundColor: `${habit.color}22`, color: habit.color }}
        >
          <HabitGlyph name={habit.icon} className="h-5 w-5" />
        </span>
        <span className="min-w-0">
          <span className="block truncate text-sm font-semibold">{habit.name}</span>
          <span className="mt-0.5 block truncate text-xs tabular-nums text-faint">
            {parts.join(" · ")}
          </span>
        </span>
      </button>

      <HabitControl
        habit={habit}
        progress={progress}
        act={(action, value) => act(habit.id, action, value)}
      />
    </div>
  );
}
