"use client";

import { Plus } from "lucide-react";
import { useState } from "react";
import { HabitControl } from "@/components/habits/habit-control";
import { HabitForm } from "@/components/habits/habit-form";
import { HabitGlyph } from "@/components/habits/habit-glyph";
import type { HabitAction } from "@/lib/client/use-habits";
import { useHabitDay } from "@/lib/client/use-habits";
import { useHabitProgress } from "@/lib/client/use-habit-progress";
import { isoDateKey } from "@/lib/time";
import type { HabitDayDTO, HabitDTO } from "@/lib/types";

function HabitChip({
  habit,
  act,
  onEdit,
}: {
  habit: HabitDayDTO;
  act: (id: string, action: HabitAction, value?: number) => Promise<unknown>;
  onEdit: (h: HabitDayDTO) => void;
}) {
  const progress = useHabitProgress(habit);
  return (
    <div className="flex shrink-0 items-center gap-1.5 rounded-full border border-border bg-surface py-1 pl-1.5 pr-1">
      <button
        type="button"
        onClick={() => onEdit(habit)}
        className="flex items-center gap-1.5"
      >
        <span
          className="grid h-6 w-6 place-items-center rounded-full"
          style={{ backgroundColor: `${habit.color}22`, color: habit.color }}
        >
          <HabitGlyph name={habit.icon} className="h-3.5 w-3.5" />
        </span>
        <span className="max-w-[8rem] truncate text-xs font-medium">{habit.name}</span>
      </button>
      <HabitControl
        habit={habit}
        progress={progress}
        act={(action, value) => act(habit.id, action, value)}
        variant="compact"
      />
    </div>
  );
}

export function HabitsStrip({ day }: { day: Date }) {
  const { habits, act } = useHabitDay(day);
  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState<HabitDTO | null>(null);

  function openCreate() {
    setEditing(null);
    setFormOpen(true);
  }

  return (
    <>
      <div className="flex items-center gap-2 overflow-x-auto pb-0.5 scrollbar-none">
        {habits.map((h) => (
          <HabitChip
            key={h.id}
            habit={h}
            act={act}
            onEdit={(habit) => {
              setEditing(habit);
              setFormOpen(true);
            }}
          />
        ))}

        <button
          type="button"
          onClick={openCreate}
          className="flex shrink-0 items-center gap-1.5 rounded-full border border-dashed border-border px-3 py-1.5 text-xs text-faint hover:border-primary/40 hover:text-primary"
        >
          <Plus className="h-3.5 w-3.5" />
          {habits.length === 0 ? "Add a habit" : "Habit"}
        </button>
      </div>

      {formOpen && (
        <HabitForm
          key={editing?.id ?? "new"}
          open
          habit={editing}
          defaultDate={isoDateKey(day)}
          onClose={() => setFormOpen(false)}
        />
      )}
    </>
  );
}
