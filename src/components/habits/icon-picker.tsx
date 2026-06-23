"use client";

import { useEffect, useRef, useState } from "react";
import { cn } from "@/lib/cn";
import { HABIT_ICON_NAMES } from "@/lib/habit-icons";
import { HabitGlyph } from "./habit-glyph";

/** Button showing the chosen icon; opens a grid popover to change it. */
export function IconPicker({
  value,
  color,
  onChange,
}: {
  value: string | null;
  color: string;
  onChange: (icon: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onDoc(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        aria-label="Change icon"
        onClick={() => setOpen((o) => !o)}
        className="grid h-12 w-12 place-items-center rounded-2xl transition-transform hover:scale-105"
        style={{ backgroundColor: `${color}22`, color }}
      >
        <HabitGlyph name={value} className="h-6 w-6" />
      </button>

      {open && (
        <div className="absolute left-0 top-14 z-30 w-64 rounded-2xl border border-border bg-surface p-2 shadow-xl">
          <div className="grid max-h-56 grid-cols-6 gap-1 overflow-y-auto">
            {HABIT_ICON_NAMES.map((name) => {
              const active = name === value;
              return (
                <button
                  key={name}
                  type="button"
                  aria-label={name}
                  onClick={() => {
                    onChange(name);
                    setOpen(false);
                  }}
                  className={cn(
                    "grid h-9 w-9 place-items-center rounded-lg transition-colors hover:bg-surface-2",
                    active && "bg-surface-2",
                  )}
                  style={active ? { color } : undefined}
                >
                  <HabitGlyph name={name} className="h-[18px] w-[18px]" />
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
