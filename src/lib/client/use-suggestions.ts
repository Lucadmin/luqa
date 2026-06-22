"use client";

import useSWR from "swr";
import { fetcher } from "@/lib/client/fetcher";
import type { SuggestionDTO } from "@/lib/types";

/** Recent description+category combos, optionally filtered by query. */
export function useSuggestions(q: string) {
  const trimmed = q.trim();
  const key = trimmed
    ? `/api/suggestions?q=${encodeURIComponent(trimmed)}`
    : "/api/suggestions";

  const { data, isLoading } = useSWR<{ suggestions: SuggestionDTO[] }>(
    key,
    fetcher,
    { keepPreviousData: true },
  );

  return { suggestions: data?.suggestions ?? [], isLoading };
}
