"use client";

import useSWR, { mutate as globalMutate } from "swr";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import type {
  ExerciseDTO,
  ExerciseHistoryDTO,
  GymImportResultDTO,
  GymLocationDTO,
  GymOverviewDTO,
  GymSessionDTO,
} from "@/lib/types";

/**
 * Saving a session can rename nothing but changes several things at once —
 * usage counts, the exercise vocabulary, every open history graph — so the
 * whole gym namespace refreshes together.
 */
function revalidateGym() {
  return globalMutate(
    (key) => typeof key === "string" && key.startsWith("/api/gym"),
  );
}

export function useGymOverview() {
  const { data, isLoading, error, mutate } = useSWR<{ overview: GymOverviewDTO }>(
    "/api/gym",
    fetcher,
  );

  return { overview: data?.overview ?? null, isLoading, error, mutate };
}

/**
 * Past performances of one exercise. `locationId` narrows it to a single gym —
 * null means every gym, which is the right default only when the numbers are
 * comparable across them.
 */
export function useExerciseHistory(
  exerciseId: string | null,
  locationId: string | null,
) {
  const key = exerciseId
    ? `/api/gym/exercises/${exerciseId}/history${
        locationId ? `?locationId=${encodeURIComponent(locationId)}` : ""
      }`
    : null;

  const { data, isLoading } = useSWR<{ history: ExerciseHistoryDTO }>(key, fetcher, {
    keepPreviousData: true,
  });

  return { history: data?.history ?? null, isLoading };
}

// --- sessions ----------------------------------------------------------------

export interface SessionExerciseInput {
  exerciseId?: string;
  name?: string;
  raw?: string;
  notes?: string;
}

export interface SessionInput {
  date?: string;
  locationId?: string | null;
  notes?: string;
  exercises?: SessionExerciseInput[];
}

export async function createSession(input: SessionInput) {
  const { session } = await apiSend<{ session: GymSessionDTO }>(
    "/api/gym",
    "POST",
    input,
  );
  await revalidateGym();
  return session;
}

export async function updateSession(id: string, patch: SessionInput) {
  const { session } = await apiSend<{ session: GymSessionDTO }>(
    `/api/gym/sessions/${id}`,
    "PATCH",
    patch,
  );
  await revalidateGym();
  return session;
}

export async function deleteSession(id: string) {
  await apiSend(`/api/gym/sessions/${id}`, "DELETE");
  await revalidateGym();
}

// --- gyms --------------------------------------------------------------------

export async function createLocation(input: {
  code: string;
  name: string;
  color?: string;
}) {
  const { location } = await apiSend<{ location: GymLocationDTO }>(
    "/api/gym/locations",
    "POST",
    input,
  );
  await revalidateGym();
  return location;
}

export async function updateLocation(
  id: string,
  patch: Partial<Omit<GymLocationDTO, "id">>,
) {
  const { location } = await apiSend<{ location: GymLocationDTO }>(
    `/api/gym/locations/${id}`,
    "PATCH",
    patch,
  );
  await revalidateGym();
  return location;
}

export async function deleteLocation(id: string) {
  const res = await apiSend<{ deleted: boolean; archived: boolean }>(
    `/api/gym/locations/${id}`,
    "DELETE",
  );
  await revalidateGym();
  return res;
}

// --- exercises ---------------------------------------------------------------

/** Renaming onto an existing name merges the two histories. */
export async function updateExercise(
  id: string,
  patch: { name?: string; notes?: string; archived?: boolean },
) {
  const res = await apiSend<{ exercise: ExerciseDTO; mergedInto: string | null }>(
    `/api/gym/exercises/${id}`,
    "PATCH",
    patch,
  );
  await revalidateGym();
  return res;
}

export async function deleteExercise(id: string) {
  const res = await apiSend<{ deleted: boolean; archived: boolean }>(
    `/api/gym/exercises/${id}`,
    "DELETE",
  );
  await revalidateGym();
  return res;
}

// --- import ------------------------------------------------------------------

export async function importGym(input: {
  markdown: string;
  dryRun?: boolean;
  replaceExisting?: boolean;
}) {
  const res = await apiSend<{ result: GymImportResultDTO; imported: boolean }>(
    "/api/gym/import",
    "POST",
    input,
  );
  if (res.imported) await revalidateGym();
  return res;
}
