"use client";

import { Check, Minus, Pause, Play } from "lucide-react";
import { useState } from "react";
import type { HabitAction } from "@/lib/client/use-habits";
import type { LiveProgress } from "@/lib/client/use-habit-progress";
import { cn } from "@/lib/cn";
import type { HabitDayDTO } from "@/lib/types";
import { ProgressRing } from "./habit-ring";

type Variant = "card" | "compact";

export function HabitControl({
  habit,
  progress,
  act,
  variant = "card",
}: {
  habit: HabitDayDTO;
  progress: LiveProgress;
  act: (action: HabitAction, value?: number) => Promise<unknown>;
  variant?: Variant;
}) {
  const [busy, setBusy] = useState(false);
  const size = variant === "card" ? 42 : 28;

  async function run(action: HabitAction, value?: number) {
    if (busy) return;
    setBusy(true);
    try {
      await act(action, value);
    } finally {
      setBusy(false);
    }
  }

  // --- TASK: a single check toggle -----------------------------------------
  if (habit.goalType === "TASK") {
    return (
      <button
        type="button"
        aria-label={habit.done ? "Mark not done" : "Mark done"}
        onClick={() => run("toggle")}
        disabled={busy}
        className={cn(
          "grid shrink-0 place-items-center rounded-full border-2 transition-all active:scale-95 disabled:opacity-60",
          habit.done ? "text-white" : "text-transparent hover:border-border-strong",
        )}
        style={{
          width: size,
          height: size,
          borderColor: habit.done ? habit.color : "var(--border-strong)",
          backgroundColor: habit.done ? habit.color : "transparent",
        }}
      >
        <Check
          className={variant === "card" ? "h-5 w-5" : "h-3.5 w-3.5"}
          strokeWidth={3}
        />
      </button>
    );
  }

  // --- COUNT: tappable ring (increments; resets once complete) -------------
  if (habit.goalType === "COUNT") {
    const target = Math.max(1, habit.targetCount);
    // Tap to add one; once complete, a tap steps back down (undo).
    const primary = () => run(habit.done ? "decrement" : "increment");
    return (
      <div className="flex shrink-0 items-center gap-1.5">
        {variant === "card" && habit.count > 0 && !habit.done && (
          <button
            type="button"
            aria-label="Decrease"
            onClick={() => run("decrement")}
            disabled={busy}
            className="grid h-7 w-7 place-items-center rounded-full text-faint hover:bg-surface-2 hover:text-foreground disabled:opacity-60"
          >
            <Minus className="h-3.5 w-3.5" />
          </button>
        )}
        <button
          type="button"
          aria-label={habit.done ? "Reset count" : "Add one"}
          onClick={primary}
          disabled={busy}
          className="flex shrink-0 rounded-full transition-transform active:scale-95 disabled:opacity-60"
        >
          <ProgressRing size={size} fraction={progress.fraction} color={habit.color}>
            {habit.done ? (
              <Check
                className={variant === "card" ? "h-5 w-5" : "h-3 w-3"}
                style={{ color: habit.color }}
                strokeWidth={3}
              />
            ) : (
              <span
                className={cn(
                  "font-semibold tabular-nums text-foreground",
                  variant === "card" ? "text-[11px]" : "text-[9px]",
                )}
              >
                {habit.count}
                <span className="text-faint">/{target}</span>
              </span>
            )}
          </ProgressRing>
        </button>
      </div>
    );
  }

  // --- TIME: play / pause around a progress ring ---------------------------
  const Icon = progress.done && !progress.running ? Check : progress.running ? Pause : Play;
  return (
    <button
      type="button"
      aria-label={progress.running ? "Pause timer" : "Start timer"}
      onClick={() => run(progress.running ? "stop" : "start")}
      disabled={busy}
      className="flex shrink-0 rounded-full transition-transform active:scale-95 disabled:opacity-60"
    >
      <ProgressRing size={size} fraction={progress.fraction} color={habit.color}>
        <Icon
          className={cn(variant === "card" ? "h-4 w-4" : "h-3 w-3", progress.running && "animate-none")}
          style={{ color: habit.color }}
          strokeWidth={progress.done ? 3 : 2}
          fill={progress.running ? "none" : progress.done ? "none" : habit.color}
        />
      </ProgressRing>
    </button>
  );
}
