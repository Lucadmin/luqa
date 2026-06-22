"use client";

import { Check, Plus, X } from "lucide-react";
import { useRef, useState } from "react";
import { useHabitLogs, useHabits } from "@/lib/client/use-habits";
import { cn } from "@/lib/cn";

export function HabitsStrip({ day }: { day: Date }) {
  const { habits, createHabit, archiveHabit } = useHabits();
  const { logged, toggle } = useHabitLogs(day);

  const [adding, setAdding] = useState(false);
  const [newName, setNewName] = useState("");
  const inputRef = useRef<HTMLInputElement>(null);

  async function handleAdd() {
    const name = newName.trim();
    if (!name) { setAdding(false); return; }
    await createHabit(name);
    setNewName("");
    setAdding(false);
  }

  if (habits.length === 0 && !adding) {
    return (
      <button
        type="button"
        onClick={() => { setAdding(true); setTimeout(() => inputRef.current?.focus(), 0); }}
        className="flex items-center gap-1.5 rounded-full border border-dashed border-border px-3 py-1.5 text-xs text-faint hover:border-primary/40 hover:text-primary"
      >
        <Plus className="h-3 w-3" />
        Add a habit
      </button>
    );
  }

  return (
    <div className="flex items-center gap-2 overflow-x-auto pb-0.5 scrollbar-none">
      {habits.map((habit) => {
        const done = logged.has(habit.id);
        return (
          <div key={habit.id} className="group relative flex-shrink-0">
            <button
              type="button"
              onClick={() => toggle(habit.id)}
              className={cn(
                "flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition-all",
                done
                  ? "border-primary/30 bg-primary/10 text-primary"
                  : "border-border bg-transparent text-muted hover:border-border-strong hover:text-foreground",
              )}
            >
              <span
                className={cn(
                  "grid h-3.5 w-3.5 shrink-0 place-items-center rounded-full border transition-colors",
                  done ? "border-primary bg-primary" : "border-current",
                )}
              >
                {done && <Check className="h-2 w-2 text-primary-foreground" strokeWidth={3} />}
              </span>
              {habit.name}
            </button>
            {/* archive button — appears on hover */}
            <button
              type="button"
              onClick={() => archiveHabit(habit.id)}
              aria-label={`Remove ${habit.name}`}
              className="absolute -right-1 -top-1 hidden h-4 w-4 place-items-center rounded-full bg-surface-2 text-faint shadow-sm hover:bg-surface-3 hover:text-foreground group-hover:grid"
            >
              <X className="h-2.5 w-2.5" />
            </button>
          </div>
        );
      })}

      {/* new habit inline input */}
      {adding ? (
        <div className="flex flex-shrink-0 items-center gap-1 rounded-full border border-primary/40 bg-primary/5 px-3 py-1.5">
          <input
            ref={inputRef}
            value={newName}
            onChange={(e) => setNewName(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") handleAdd();
              if (e.key === "Escape") { setNewName(""); setAdding(false); }
            }}
            onBlur={handleAdd}
            placeholder="Habit name…"
            className="w-32 bg-transparent text-xs text-foreground placeholder:text-faint focus:outline-none"
          />
        </div>
      ) : (
        <button
          type="button"
          onClick={() => { setAdding(true); setTimeout(() => inputRef.current?.focus(), 0); }}
          aria-label="Add habit"
          className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full border border-dashed border-border text-faint hover:border-primary/40 hover:text-primary"
        >
          <Plus className="h-3.5 w-3.5" />
        </button>
      )}
    </div>
  );
}
