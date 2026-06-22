"use client";

import { useMemo } from "react";
import useSWR from "swr";
import { fetcher } from "@/lib/client/fetcher";
import { startOfLocalDay } from "@/lib/time";
import type { CategoryDTO, TimeEntryDTO } from "@/lib/types";

export interface WeekData {
  entries: TimeEntryDTO[];
  categories: CategoryDTO[];
  totalsByCategory: Record<string, number>;
  totalMinutes: number;
}

function startOfWeekMonday(d: Date): Date {
  const c = startOfLocalDay(d);
  const day = c.getDay(); // 0 = Sun
  const diff = (day === 0 ? -6 : 1 - day);
  c.setDate(c.getDate() + diff);
  return c;
}

export function useWeek(weekStart: Date) {
  const { from, to } = useMemo(() => {
    const start = weekStart;
    const end = new Date(start);
    end.setDate(end.getDate() + 7);
    return { from: start.toISOString(), to: end.toISOString() };
  }, [weekStart]);

  const key = `/api/week?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`;
  const { data, isLoading, error, mutate } = useSWR<WeekData>(key, fetcher);

  return {
    data: data ?? { entries: [], categories: [], totalsByCategory: {}, totalMinutes: 0 },
    isLoading,
    error,
    mutate,
  };
}

export { startOfWeekMonday };
