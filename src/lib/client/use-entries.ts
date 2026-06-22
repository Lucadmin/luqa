"use client";

import { useMemo } from "react";
import useSWR from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import { endOfLocalDay, startOfLocalDay } from "@/lib/time";
import type { TimeEntryDTO } from "@/lib/types";

export interface EntryInput {
  description?: string;
  categoryId?: string | null;
  startTime: string; // ISO
  endTime?: string | null; // ISO or null (running)
}

/** Entries for the local day that `day` falls on. */
export function useEntries(day: Date) {
  const { from, to } = useMemo(() => {
    return {
      from: startOfLocalDay(day).toISOString(),
      to: endOfLocalDay(day).toISOString(),
    };
  }, [day]);

  const key = `/api/entries?from=${encodeURIComponent(from)}&to=${encodeURIComponent(to)}`;
  const { data, error, isLoading, mutate } = useSWR<{
    entries: TimeEntryDTO[];
  }>(key, fetcher, { revalidateOnFocus: true });

  const entries = data?.entries ?? [];

  async function createEntry(input: EntryInput) {
    const res = await apiSend<{ entry: TimeEntryDTO }>(
      "/api/entries",
      "POST",
      input,
    );
    await mutate();
    return res.entry;
  }

  async function updateEntry(id: string, patch: Partial<EntryInput>) {
    const res = await apiSend<{ entry: TimeEntryDTO }>(
      `/api/entries/${id}`,
      "PATCH",
      patch,
    );
    await mutate();
    return res.entry;
  }

  async function deleteEntry(id: string) {
    await apiSend(`/api/entries/${id}`, "DELETE");
    await mutate();
  }

  return {
    entries,
    isLoading,
    error,
    mutate,
    createEntry,
    updateEntry,
    deleteEntry,
  };
}
