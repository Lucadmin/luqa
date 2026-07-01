"use client";

import useSWR from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import type { LifeOverviewDTO, LifePeriodDTO, WeekNoteDTO } from "@/lib/types";

const KEY = "/api/life";

const EMPTY: LifeOverviewDTO = {
  birthDate: null,
  lifeExpectancyYears: 90,
  periods: [],
  notes: [],
};

export interface PeriodInput {
  name: string;
  color: string;
  startDate: string;
  endDate: string | null;
}

export function useLife() {
  const { data, isLoading, error, mutate } = useSWR<{ life: LifeOverviewDTO }>(
    KEY,
    fetcher,
  );

  const life = data?.life ?? EMPTY;

  async function createPeriod(input: PeriodInput) {
    const res = await apiSend<{ period: LifePeriodDTO }>(
      "/api/life/periods",
      "POST",
      input,
    );
    await mutate();
    return res.period;
  }

  async function updatePeriod(id: string, input: Partial<PeriodInput>) {
    await apiSend<{ period: LifePeriodDTO }>(`/api/life/periods/${id}`, "PATCH", input);
    await mutate();
  }

  async function deletePeriod(id: string) {
    // Optimistically drop it from the list, then persist.
    await mutate(
      async () => {
        await apiSend(`/api/life/periods/${id}`, "DELETE");
        return { life: { ...life, periods: life.periods.filter((p) => p.id !== id) } };
      },
      {
        optimisticData: {
          life: { ...life, periods: life.periods.filter((p) => p.id !== id) },
        },
        rollbackOnError: true,
        revalidate: false,
      },
    );
  }

  async function saveNote(note: WeekNoteDTO) {
    await apiSend("/api/life/notes", "POST", note);
    await mutate();
  }

  return {
    life,
    isLoading,
    error,
    mutate,
    createPeriod,
    updatePeriod,
    deletePeriod,
    saveNote,
  };
}
