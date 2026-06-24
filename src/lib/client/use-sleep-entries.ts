"use client";

import { useMemo } from "react";
import useSWR from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import { minutesToDate } from "@/lib/time";
import type { SleepEntryDTO } from "@/lib/types";

export interface SleepEntryPatch {
  title?: string | null;
  startTime?: string;
  endTime?: string;
  sleepMinutes?: number | null;
  awakeMinutes?: number | null;
  lightMinutes?: number | null;
  deepMinutes?: number | null;
  remMinutes?: number | null;
}

/** Sleep sessions whose wake time falls inside the displayed logical day. */
export function useSleepEntries(day: Date, dayStartHour: number) {
  const { from, to } = useMemo(() => {
    const start = minutesToDate(day, dayStartHour * 60);
    const end = new Date(start);
    end.setDate(end.getDate() + 1);
    return { from: start.toISOString(), to: end.toISOString() };
  }, [day, dayStartHour]);

  const key = `/api/sleep?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`;
  const { data, error, isLoading, mutate } = useSWR<{
    entries: SleepEntryDTO[];
  }>(key, fetcher, { revalidateOnFocus: true });

  async function updateSleepEntry(id: string, patch: SleepEntryPatch) {
    const res = await apiSend<{ entry: SleepEntryDTO }>(
      `/api/sleep/${id}`,
      "PATCH",
      patch,
    );
    await mutate();
    return res.entry;
  }

  return {
    sleepEntries: data?.entries ?? [],
    isLoading,
    error,
    mutate,
    updateSleepEntry,
  };
}
