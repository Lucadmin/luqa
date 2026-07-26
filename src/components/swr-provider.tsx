"use client";

import { SWRConfig } from "swr";
import { localStorageCacheProvider } from "@/lib/client/swr-local-cache";

export function SwrProvider({ children }: { children: React.ReactNode }) {
  return (
    <SWRConfig value={{ provider: localStorageCacheProvider }}>
      {children}
    </SWRConfig>
  );
}
