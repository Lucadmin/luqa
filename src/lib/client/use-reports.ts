"use client";

import useSWR from "swr";
import { fetcher } from "@/lib/client/fetcher";
import { startOfWeek } from "@/lib/client/use-week";
import { startOfLocalDay } from "@/lib/time";
import type { CategoryDTO, SleepReportDTO } from "@/lib/types";

export interface ReportsData {
  categories: CategoryDTO[];
  totalsByCategory: Record<string, number>;
  dailyTotals: Record<string, number>;
  /** Per-day, per-category minutes: { "2025-06-10": { catId: minutes } } */
  dailyByCategory: Record<string, Record<string, number>>;
  totalMinutes: number;
  sleep: SleepReportDTO;
}

export type RangeMode = "week" | "30d" | "90d";

const EMPTY: ReportsData = {
  categories: [],
  totalsByCategory: {},
  dailyTotals: {},
  dailyByCategory: {},
  totalMinutes: 0,
  sleep: {
    dailySleep: {},
    totalMinutes: 0,
    averageMinutes: 0,
    daysWithSleep: 0,
    bestDay: null,
  },
};

/**
 * Resolve a [from, to) date range for a mode and navigation offset.
 * `week` is calendar-aligned (and respects the week-start preference); the
 * rolling ranges shift by their own span.
 */
export function computeRange(
  mode: RangeMode,
  offset: number,
  weekStartsOn: number,
): { from: Date; to: Date } {
  if (mode === "week") {
    const from = startOfWeek(new Date(), weekStartsOn);
    from.setDate(from.getDate() + offset * 7);
    const to = new Date(from);
    to.setDate(to.getDate() + 7);
    return { from, to };
  }
  const span = mode === "30d" ? 30 : 90;
  const to = startOfLocalDay(new Date());
  to.setDate(to.getDate() + 1 + offset * span);
  const from = new Date(to);
  from.setDate(from.getDate() - span);
  return { from, to };
}

/** "Jun 17 – Jun 23" for the inclusive span [from, to). */
export function rangeLabel(from: Date, to: Date): string {
  const last = new Date(to);
  last.setDate(last.getDate() - 1);
  const opts: Intl.DateTimeFormatOptions = { month: "short", day: "numeric" };
  return `${from.toLocaleDateString(undefined, opts)} – ${last.toLocaleDateString(undefined, opts)}`;
}

export function useReportsData(from: Date, to: Date) {
  const key = `/api/reports?from=${encodeURIComponent(from.toISOString())}&to=${encodeURIComponent(to.toISOString())}`;
  const { data, isLoading, error } = useSWR<ReportsData>(key, fetcher);
  return { data: data ?? EMPTY, isLoading, error };
}
