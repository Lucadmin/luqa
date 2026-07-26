"use client";

import useSWR, { useSWRConfig } from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
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

const PREFIX = "/api/sleep?";

/** Sleep sessions whose wake time falls inside [from, to). */
export function useSleepRange(from: Date, to: Date) {
  const { mutate: mutateAll } = useSWRConfig();

  const key = `${PREFIX}from=${encodeURIComponent(from.toISOString())}&to=${encodeURIComponent(to.toISOString())}`;
  const { data, error, isLoading, mutate } = useSWR<{
    entries: SleepEntryDTO[];
  }>(key, fetcher, { revalidateOnFocus: true, keepPreviousData: true });

  async function updateSleepEntry(id: string, patch: SleepEntryPatch) {
    const res = await apiSend<{ entry: SleepEntryDTO }>(
      `/api/sleep/${id}`,
      "PATCH",
      patch,
    );
    await mutateAll((k) => typeof k === "string" && k.startsWith(PREFIX));
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
