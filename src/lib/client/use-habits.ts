"use client";

import useSWR, { mutate as globalMutate } from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import { isoDateKey } from "@/lib/time";
import type { HabitDayDTO, HabitDTO, HabitStatDTO } from "@/lib/types";

export type { HabitDTO, HabitDayDTO, HabitStatDTO };

/** Revalidate everything whose totals can shift when a linked timer runs. */
function revalidateTracking() {
  return globalMutate(
    (key) =>
      typeof key === "string" &&
      (key.startsWith("/api/entries") ||
        key.startsWith("/api/reports") ||
        key.startsWith("/api/week") ||
        key.startsWith("/api/habits/day") ||
        key.startsWith("/api/habits/stats")),
  );
}

// --- habit configuration ----------------------------------------------------

export function useHabits() {
  const { data, isLoading, mutate } = useSWR<{ habits: HabitDTO[] }>(
    "/api/habits",
    fetcher,
  );

  return {
    habits: data?.habits ?? [],
    isLoading,
    mutate,
  };
}

export async function createHabit(input: Partial<HabitDTO> & { name: string }) {
  const { habit } = await apiSend<{ habit: HabitDTO }>("/api/habits", "POST", input);
  await globalMutate("/api/habits");
  await revalidateTracking();
  return habit;
}

export async function updateHabit(id: string, patch: Partial<HabitDTO> & { archived?: boolean }) {
  const res = await apiSend<{ habit: HabitDTO }>(`/api/habits/${id}`, "PATCH", patch);
  await globalMutate("/api/habits");
  await revalidateTracking();
  return res.habit;
}

export async function archiveHabit(id: string) {
  await apiSend(`/api/habits/${id}`, "DELETE");
  await globalMutate("/api/habits");
  await revalidateTracking();
}

export async function reorderHabits(ids: string[]) {
  await apiSend("/api/habits/reorder", "POST", { ids });
  await globalMutate("/api/habits");
}

// --- a single day's habits + progress --------------------------------------

export type HabitAction =
  | "toggle"
  | "increment"
  | "decrement"
  | "start"
  | "stop"
  | "setCount"
  | "addSeconds";

export function useHabitDay(date: Date) {
  const dateKey = isoDateKey(date);
  const key = `/api/habits/day?date=${dateKey}`;
  const { data, isLoading, mutate } = useSWR<{ date: string; habits: HabitDayDTO[] }>(
    key,
    fetcher,
  );

  const habits = data?.habits ?? [];

  async function act(habitId: string, action: HabitAction, value?: number) {
    const res = await apiSend<{ habit: HabitDayDTO }>(
      `/api/habits/${habitId}/log`,
      "POST",
      { date: dateKey, action, value },
    );
    // Patch the affected habit in place, then refresh dependent views.
    await mutate(
      (cur) =>
        cur
          ? { ...cur, habits: cur.habits.map((h) => (h.id === habitId ? res.habit : h)) }
          : cur,
      { revalidate: false },
    );
    await revalidateTracking();
    return res.habit;
  }

  return { dateKey, habits, isLoading, mutate, act };
}

// --- range analytics (strip dots + stats view) ------------------------------

export function useHabitStats(from: string, to: string) {
  const { data, isLoading } = useSWR<{ stats: HabitStatDTO[] }>(
    `/api/habits/stats?from=${from}&to=${to}`,
    fetcher,
  );
  const byHabit = new Map((data?.stats ?? []).map((s) => [s.habitId, s]));
  return { stats: data?.stats ?? [], byHabit, isLoading };
}
