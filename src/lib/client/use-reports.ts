"use client";

import { useMemo } from "react";
import useSWR from "swr";
import { fetcher } from "@/lib/client/fetcher";
import { startOfLocalDay } from "@/lib/time";
import type { CategoryDTO } from "@/lib/types";

export interface ReportsData {
  categories: CategoryDTO[];
  totalsByCategory: Record<string, number>;
  dailyTotals: Record<string, number>;
  /** Per-day, per-category minutes: { "2025-06-10": { catId: minutes } } */
  dailyByCategory: Record<string, Record<string, number>>;
  totalMinutes: number;
}

export type RangePreset = "7d" | "30d" | "90d";

export function rangeForPreset(preset: RangePreset): { from: Date; to: Date } {
  const to = startOfLocalDay(new Date());
  to.setDate(to.getDate() + 1); // exclusive end (tomorrow midnight)
  const from = new Date(to);
  const days = preset === "7d" ? 7 : preset === "30d" ? 30 : 90;
  from.setDate(from.getDate() - days);
  return { from, to };
}

export function useReports(preset: RangePreset) {
  const { from, to } = useMemo(() => rangeForPreset(preset), [preset]);

  const key = `/api/reports?from=${encodeURIComponent(from.toISOString())}&to=${encodeURIComponent(to.toISOString())}`;
  const { data, isLoading, error } = useSWR<ReportsData>(key, fetcher);

  return {
    data: data ?? { categories: [], totalsByCategory: {}, dailyTotals: {}, dailyByCategory: {}, totalMinutes: 0 },
    isLoading,
    error,
    from,
    to,
  };
}
