"use client";

import useSWR, { useSWRConfig } from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import type { TimeEntryDTO } from "@/lib/types";

export interface EntryInput {
  description?: string;
  categoryId?: string | null;
  startTime: string; // ISO
  endTime?: string | null; // ISO or null (running)
}

const PREFIX = "/api/entries?";

/**
 * Entries overlapping [from, to). The infinite timeline slides this window as
 * it scrolls, so a write has to refresh *every* cached window rather than just
 * the one currently on screen.
 */
export function useEntriesRange(from: Date, to: Date) {
  const { mutate: mutateAll } = useSWRConfig();

  const key = `${PREFIX}from=${encodeURIComponent(from.toISOString())}&to=${encodeURIComponent(to.toISOString())}`;
  const { data, error, isLoading, mutate } = useSWR<{
    entries: TimeEntryDTO[];
  }>(key, fetcher, { revalidateOnFocus: true, keepPreviousData: true });

  /** Revalidate all cached windows — a write can land in any of them. */
  function refresh() {
    return mutateAll((k) => typeof k === "string" && k.startsWith(PREFIX));
  }

  async function createEntry(input: EntryInput) {
    const res = await apiSend<{ entry: TimeEntryDTO }>(
      "/api/entries",
      "POST",
      input,
    );
    await refresh();
    return res.entry;
  }

  async function updateEntry(id: string, patch: Partial<EntryInput>) {
    const res = await apiSend<{ entry: TimeEntryDTO }>(
      `/api/entries/${id}`,
      "PATCH",
      patch,
    );
    await refresh();
    return res.entry;
  }

  async function deleteEntry(id: string) {
    await apiSend(`/api/entries/${id}`, "DELETE");
    await refresh();
  }

  return {
    entries: data?.entries ?? [],
    isLoading,
    error,
    mutate,
    createEntry,
    updateEntry,
    deleteEntry,
  };
}
