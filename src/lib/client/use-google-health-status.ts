"use client";

import useSWR from "swr";
import { fetcher } from "@/lib/client/fetcher";
import type { GoogleHealthStatusDTO } from "@/lib/types";

const EMPTY: GoogleHealthStatusDTO = {
  connected: false,
  googleEmail: null,
  healthUserId: null,
  lastSynced: null,
};

export function useGoogleHealthStatus() {
  const { data, isLoading, error, mutate } = useSWR<GoogleHealthStatusDTO>(
    "/api/health/google/status",
    fetcher,
  );

  return { status: data ?? EMPTY, isLoading, error, mutate };
}
