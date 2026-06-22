"use client";

import useSWR from "swr";
import { fetcher } from "@/lib/client/fetcher";

export interface GoogleStatus {
  connected: boolean;
  googleEmail?: string;
  calendarId?: string;
  lastSynced?: string | null;
  webhookActive?: boolean;
}

export function useGoogleStatus() {
  const { data, error, isLoading, mutate } = useSWR<GoogleStatus>(
    "/api/google/status",
    fetcher,
  );

  return {
    status: data ?? { connected: false },
    isLoading,
    error,
    mutate,
  };
}
