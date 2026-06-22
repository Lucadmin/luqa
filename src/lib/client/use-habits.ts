"use client";

import useSWR from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import { isoDateKey } from "@/lib/time";

export interface HabitDTO {
  id: string;
  name: string;
  order: number;
  createdAt: string;
}

export function useHabits() {
  const { data, mutate } = useSWR<{ habits: HabitDTO[] }>("/api/habits", fetcher);
  const habits = data?.habits ?? [];

  async function createHabit(name: string) {
    await apiSend("/api/habits", "POST", { name });
    await mutate();
  }

  async function archiveHabit(id: string) {
    await apiSend(`/api/habits/${id}`, "DELETE");
    await mutate();
  }

  return { habits, createHabit, archiveHabit };
}

export function useHabitLogs(date: Date) {
  const dateKey = isoDateKey(date);
  const { data, mutate } = useSWR<{ logged: string[] }>(
    `/api/habits/logs?date=${dateKey}`,
    fetcher,
  );
  const logged = new Set(data?.logged ?? []);

  async function toggle(habitId: string) {
    // Optimistic update
    const wasLogged = logged.has(habitId);
    const next = new Set(logged);
    wasLogged ? next.delete(habitId) : next.add(habitId);
    await mutate({ logged: [...next] }, false);

    try {
      await apiSend("/api/habits/logs", "POST", { habitId, date: dateKey });
    } catch {
      await mutate(); // revert on error
    }
  }

  return { logged, toggle };
}
