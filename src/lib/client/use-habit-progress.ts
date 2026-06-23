"use client";

import { useNow } from "@/lib/client/use-now";
import type { HabitDayDTO } from "@/lib/types";

export interface LiveProgress {
  /** A TIME habit's timer is currently running. */
  running: boolean;
  /** Live seconds toward a TIME goal (includes the running stretch). */
  liveSeconds: number;
  /** 0..1 toward the day's goal. */
  fraction: number;
  /** Whether the goal is met right now. */
  done: boolean;
}

/** Resolve a habit's live progress, ticking once a second while a timer runs. */
export function useHabitProgress(habit: HabitDayDTO): LiveProgress {
  const running = habit.goalType === "TIME" && !!habit.runningSince;
  const now = useNow(running);

  let liveSeconds = habit.seconds;
  if (running && habit.runningSince) {
    liveSeconds += Math.max(0, (now - Date.parse(habit.runningSince)) / 1000);
  }

  switch (habit.goalType) {
    case "TASK":
      return { running, liveSeconds, fraction: habit.done ? 1 : 0, done: habit.done };
    case "COUNT": {
      const target = Math.max(1, habit.targetCount);
      return {
        running,
        liveSeconds,
        fraction: Math.min(1, habit.count / target),
        done: habit.count >= target,
      };
    }
    case "TIME": {
      const target = Math.max(1, habit.targetSeconds);
      return {
        running,
        liveSeconds,
        fraction: Math.min(1, liveSeconds / target),
        done: liveSeconds >= target,
      };
    }
  }
}
