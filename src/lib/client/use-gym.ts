"use client";

import useSWR, { mutate as globalMutate } from "swr";
import useSWRInfinite, { unstable_serialize } from "swr/infinite";
import { useCallback, useMemo } from "react";
import { apiSend, fetcher } from "@/lib/client/fetcher";
import type {
  ExerciseDTO,
  ExerciseHistoryDTO,
  GymLocationDTO,
  GymOverviewDTO,
  GymSessionDTO,
} from "@/lib/types";

const SESSIONS_PAGE_SIZE = 20;

/**
 * Saving a session can rename nothing but changes several things at once —
 * usage counts, the exercise vocabulary, every open history graph — so the
 * whole gym namespace refreshes together.
 */
interface SessionsPage {
  sessions: GymSessionDTO[];
  nextCursor: string | null;
}

function sessionPageKey(_pageIndex: number, previousPage: SessionsPage | null) {
  if (previousPage && previousPage.nextCursor === null) return null;

  const params = new URLSearchParams({ limit: String(SESSIONS_PAGE_SIZE) });
  if (previousPage?.nextCursor) params.set("cursor", previousPage.nextCursor);
  return `/api/gym/sessions?${params.toString()}`;
}

const SESSION_LIST_KEY = unstable_serialize(sessionPageKey);

async function revalidateGym() {
  await Promise.all([
    globalMutate(
      (key) =>
        typeof key === "string" &&
        key.startsWith("/api/gym") &&
        !key.startsWith("/api/gym/sessions?"),
    ),
    globalMutate(SESSION_LIST_KEY),
  ]);
}

function revalidateGymInBackground() {
  void revalidateGym().catch(() => {
    // The write already succeeded; let SWR retry the refresh later.
  });
}

export function useGymOverview() {
  const { data, isLoading, error, mutate } = useSWR<{ overview: GymOverviewDTO }>(
    "/api/gym",
    fetcher,
  );

  return { overview: data?.overview ?? null, isLoading, error, mutate };
}

/**
 * Sessions, newest first, loaded a page at a time. `loadMore` is meant to be
 * called from an IntersectionObserver at the bottom of the list — the point is
 * that scrolling into three years of history never has to wait on all of it
 * arriving up front.
 */
export function useGymSessions() {
  const { data, error, isLoading, size, setSize, mutate } =
    useSWRInfinite<SessionsPage>(
      sessionPageKey,
      fetcher,
    );

  const sessions = useMemo(() => {
    const seen = new Set<string>();
    return (
      data?.flatMap((page) =>
        page.sessions.filter((session) => {
          if (seen.has(session.id)) return false;
          seen.add(session.id);
          return true;
        }),
      ) ?? []
    );
  }, [data]);
  const hasMore = Boolean(data?.at(-1)?.nextCursor);
  const isLoadingMore =
    isLoading ||
    (size > 0 && data !== undefined && typeof data[size - 1] === "undefined");
  const loadMore = useCallback(() => setSize((current) => current + 1), [setSize]);

  return {
    sessions,
    error,
    isLoading,
    isLoadingMore,
    hasMore,
    loadMore,
    mutate,
  };
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

export interface SessionSetInput {
  weight: number | null;
  reps: number | null;
  note: string | null;
}

export interface SessionExerciseInput {
  exerciseId?: string;
  name?: string;
  sets?: SessionSetInput[];
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
  revalidateGymInBackground();
  return session;
}

export async function updateSession(id: string, patch: SessionInput) {
  const { session } = await apiSend<{ session: GymSessionDTO }>(
    `/api/gym/sessions/${id}`,
    "PATCH",
    patch,
  );
  revalidateGymInBackground();
  return session;
}

/**
 * Same write as `updateSession`, but skips the namespace-wide revalidate.
 * Meant for the debounced auto-save while a session is actively being
 * edited — refetching the whole gym namespace every ~600ms while someone is
 * mid-set would be wasteful and would jostle anything else on screen. The
 * editor flushes with a real `updateSession` once, when it closes.
 */
export async function patchSessionSilently(id: string, patch: SessionInput) {
  const { session } = await apiSend<{ session: GymSessionDTO }>(
    `/api/gym/sessions/${id}`,
    "PATCH",
    patch,
  );
  return session;
}

export async function deleteSession(id: string) {
  await apiSend(`/api/gym/sessions/${id}`, "DELETE");
  revalidateGymInBackground();
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

export async function mergeExercise(
  sourceExerciseId: string,
  targetExerciseId: string,
) {
  const res = await apiSend<{
    exercise: ExerciseDTO;
    mergedExerciseId: string;
    movedEntries: number;
  }>(`/api/gym/exercises/${sourceExerciseId}/merge`, "POST", {
    targetExerciseId,
  });
  await globalMutate<{ overview: GymOverviewDTO }>(
    "/api/gym",
    (current) =>
      current
        ? {
            overview: {
              ...current.overview,
              exercises: current.overview.exercises
                .filter((exercise) => exercise.id !== sourceExerciseId)
                .map((exercise) =>
                  exercise.id === targetExerciseId ? res.exercise : exercise,
                ),
            },
          }
        : current,
    { revalidate: false },
  );
  revalidateGymInBackground();
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
