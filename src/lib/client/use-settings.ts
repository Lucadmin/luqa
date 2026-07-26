"use client";

import useSWR, { mutate as globalMutate } from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import { DAY_START_HOUR } from "@/lib/time";
import type { SettingsDTO } from "@/lib/types";

const DEFAULTS: SettingsDTO = {
  name: null,
  email: "",
  currency: "EUR",
  dayStartHour: DAY_START_HOUR,
  dailyGoalMinutes: 480,
  weekStartsOn: 1,
  birthDate: null,
  lifeExpectancyYears: 90,
};

const KEY = "/api/settings";

export function useSettings() {
  const { data, isLoading, error, mutate } = useSWR<{ settings: SettingsDTO }>(
    KEY,
    fetcher,
  );

  const settings = data?.settings ?? DEFAULTS;

  async function updateSettings(patch: Partial<SettingsDTO>) {
    // Optimistic: reflect the change immediately, then persist.
    await mutate(
      async () => {
        const res = await apiSend<{ settings: SettingsDTO }>(KEY, "PATCH", patch);
        return res;
      },
      {
        optimisticData: { settings: { ...settings, ...patch } },
        rollbackOnError: true,
        revalidate: false,
      },
    );
    // Day grouping for reports/week is recomputed from settings — revalidate
    // anything that buckets by the logical day so it reflects the new cutoff.
    await globalMutate(
      (key) =>
        typeof key === "string" &&
        (key.startsWith("/api/reports") || key.startsWith("/api/week")),
    );
  }

  return { settings, isLoading, error, mutate, updateSettings };
}
