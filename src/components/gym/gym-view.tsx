"use client";

import { Dumbbell, MapPin, Plus, Search } from "lucide-react";
import dynamic from "next/dynamic";
import { useDeferredValue, useMemo, useState } from "react";
import { AppPage, AppPageHeader } from "@/components/ui/app-page";
import { Button } from "@/components/ui/button";
import { EmptyState } from "@/components/ui/empty-state";
import { InfiniteListFooter } from "@/components/ui/infinite-list-footer";
import { Input } from "@/components/ui/input";
import { useGymOverview, useGymSessions } from "@/lib/client/use-gym";
import { cn } from "@/lib/cn";
import { formatDayLabel } from "@/lib/time";
import type { ExerciseDTO, GymLocationDTO, GymSessionDTO } from "@/lib/types";

// Modals only matter once opened — load them on demand instead of paying
// for their JS on every visit to the gym tab.
const ExerciseHistorySheet = dynamic(() =>
  import("@/components/gym/exercise-history").then((m) => m.ExerciseHistorySheet),
);
const LocationsSheet = dynamic(() =>
  import("@/components/gym/locations-sheet").then((m) => m.LocationsSheet),
);
const SessionSheet = dynamic(() =>
  import("@/components/gym/session-sheet").then((m) => m.SessionSheet),
);

type Tab = "sessions" | "exercises";

const EMPTY_LOCATIONS: GymLocationDTO[] = [];
const EMPTY_EXERCISES: ExerciseDTO[] = [];

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

export function GymView() {
  const { overview, isLoading: isLoadingOverview } = useGymOverview();
  const {
    sessions,
    isLoading: isLoadingSessions,
    isLoadingMore,
    hasMore,
    loadMore,
  } = useGymSessions();

  const [tab, setTab] = useState<Tab>("sessions");
  const [sessionOpen, setSessionOpen] = useState(false);
  const [editing, setEditing] = useState<GymSessionDTO | null>(null);
  const [locationsOpen, setLocationsOpen] = useState(false);
  const [historyId, setHistoryId] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  const locations = overview?.locations ?? EMPTY_LOCATIONS;
  const exercises = overview?.exercises ?? EMPTY_EXERCISES;
  const locationById = useMemo(
    () => new Map(locations.map((location) => [location.id, location])),
    [locations],
  );

  // Sessions load newest first, so if today's exists it's always the first
  // page's first row — no need to wait for the rest of the history.
  const todaySession = sessions.find((s) => s.date === todayKey()) ?? null;

  function newSession() {
    // Tapping "+" continues today's session if one's already going, rather
    // than starting a second one for the same day.
    setEditing(todaySession);
    setSessionOpen(true);
  }

  function editSession(session: GymSessionDTO) {
    setEditing(session);
    setSessionOpen(true);
  }

  const deferredQuery = useDeferredValue(query);
  const q = deferredQuery.trim().toLowerCase();
  const shownExercises = useMemo(
    () =>
      exercises
        .filter((exercise) => !exercise.archived)
        .filter((exercise) => !q || exercise.name.toLowerCase().includes(q))
        .sort((a, b) => {
          if (a.lastPerformed !== b.lastPerformed) {
            return (b.lastPerformed ?? "").localeCompare(a.lastPerformed ?? "");
          }
          return b.sessionCount - a.sessionCount;
        }),
    [exercises, q],
  );

  const historyExercise = historyId
    ? exercises.find((e) => e.id === historyId)
    : null;

  return (
    <AppPage>
      <AppPageHeader
        title="Gym"
        actions={
          <div className="flex items-center gap-2">
            <Button
              variant="ghost"
              size="icon-sm"
              onClick={() => setLocationsOpen(true)}
              aria-label="Gyms"
            >
              <MapPin className="h-4.5 w-4.5" />
            </Button>
            <Button size="icon-sm" onClick={newSession} aria-label="New session">
              <Plus className="h-4.5 w-4.5" />
            </Button>
          </div>
        }
      />

      {/* headline: how much has actually happened */}
      {(overview?.totalSessions ?? 0) > 0 && (
        <p className="mt-3 text-sm text-muted">
          {overview?.totalSessions} session{overview?.totalSessions === 1 ? "" : "s"}{" "}
          logged
          {locations.length > 0 && ` · ${locations.length} gym${locations.length === 1 ? "" : "s"}`}
        </p>
      )}

      <div className="mt-5 flex gap-1 border-b border-border">
        <TabButton active={tab === "sessions"} onClick={() => setTab("sessions")}>
          Sessions
        </TabButton>
        <TabButton active={tab === "exercises"} onClick={() => setTab("exercises")}>
          Exercises
        </TabButton>
      </div>

      {tab === "sessions" ? (
        <div className="mt-4">
          {isLoadingSessions ? (
            <div className="flex flex-col gap-2">
              {[0, 1, 2].map((i) => (
                <div key={i} className="h-16 animate-pulse rounded-2xl bg-surface-2" />
              ))}
            </div>
          ) : sessions.length === 0 ? (
            <EmptyState
              icon={<Dumbbell className="h-6 w-6" />}
              title="No sessions yet"
              description="Log today’s and the history builds itself from there."
              actionLabel={
                <>
                  <Plus className="h-4 w-4" />
                  Log a session
                </>
              }
              onAction={newSession}
            />
          ) : (
            <>
              <ul className="flex flex-col gap-1.5">
                {sessions.map((session) => (
                  <li key={session.id}>
                    <SessionRow
                      session={session}
                      location={
                        session.locationId ? locationById.get(session.locationId) : undefined
                      }
                      onOpen={() => editSession(session)}
                    />
                  </li>
                ))}
              </ul>

              <InfiniteListFooter
                hasMore={hasMore}
                isLoading={isLoadingMore}
                onLoadMore={loadMore}
                label="Load more sessions"
              />
            </>
          )}
        </div>
      ) : (
        <div className="mt-4">
          {isLoadingOverview && exercises.length === 0 ? null : exercises.length > 0 && (
            <div className="relative mb-3">
              <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-faint" />
              <Input
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search exercises"
                className="pl-9"
              />
            </div>
          )}

          {shownExercises.length === 0 ? (
            <p className="py-14 text-center text-xs text-faint">
              {q ? "No matches." : "Log a session to start building this list."}
            </p>
          ) : (
            <ul className="divide-y divide-border">
              {shownExercises.map((exercise) => (
                <li key={exercise.id}>
                  <ExerciseRow
                    exercise={exercise}
                    onOpen={() => setHistoryId(exercise.id)}
                  />
                </li>
              ))}
            </ul>
          )}
        </div>
      )}

      {sessionOpen && (
        <SessionSheet
          key={editing?.id ?? "new"}
          open
          onClose={() => setSessionOpen(false)}
          session={editing}
          locations={locations}
          exercises={exercises}
          sessions={sessions}
          onManageLocations={() => setLocationsOpen(true)}
        />
      )}

      {locationsOpen && (
        <LocationsSheet
          open
          onClose={() => setLocationsOpen(false)}
          locations={locations}
        />
      )}

      {historyId && (
        <ExerciseHistorySheet
          exerciseId={historyId}
          name={historyExercise?.name ?? ""}
          locations={locations}
          onClose={() => setHistoryId(null)}
        />
      )}
    </AppPage>
  );
}

function TabButton({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "relative px-1 pb-2.5 text-sm font-medium transition-colors",
        active ? "text-foreground" : "text-faint hover:text-foreground",
      )}
    >
      {children}
      {active && (
        <span className="absolute inset-x-0 -bottom-px h-0.5 rounded-full bg-primary" />
      )}
    </button>
  );
}

function SessionRow({
  session,
  location,
  onOpen,
}: {
  session: GymSessionDTO;
  location?: { code: string; color: string };
  onOpen: () => void;
}) {
  const names = session.exercises.map((e) => e.name);
  const preview = names.slice(0, 3).join(", ") + (names.length > 3 ? `, +${names.length - 3}` : "");
  const isToday = session.date === todayKey();

  return (
    <button
      type="button"
      onClick={onOpen}
      className={cn(
        "flex w-full items-center gap-3 rounded-2xl border px-3.5 py-3 text-left transition-colors hover:bg-surface-2",
        isToday ? "border-primary/40 bg-primary/5" : "border-border bg-surface",
      )}
    >
      <div className="flex w-14 shrink-0 flex-col items-center">
        <span className="text-xs font-medium tabular-nums text-faint">
          {isToday ? "Today" : formatDayLabel(session.date)}
        </span>
      </div>

      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">
          {preview || (isToday ? "In progress — tap to add exercises" : "No exercises logged")}
        </p>
        {session.notes && (
          <p className="truncate text-xs text-faint">{session.notes}</p>
        )}
      </div>

      {location && (
        <span
          className="shrink-0 rounded-full px-2 py-0.5 text-[11px] font-semibold text-white"
          style={{ backgroundColor: location.color }}
        >
          {location.code}
        </span>
      )}
    </button>
  );
}

function ExerciseRow({
  exercise,
  onOpen,
}: {
  exercise: ExerciseDTO;
  onOpen: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onOpen}
      className="flex w-full items-center gap-3 py-2.5 text-left transition-colors hover:bg-surface-2"
    >
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">{exercise.name}</p>
        <p className="truncate text-xs tabular-nums text-faint">
          {exercise.lastRaw || "—"}
        </p>
      </div>
      <span className="shrink-0 text-xs text-faint">
        {exercise.lastPerformed ? formatDayLabel(exercise.lastPerformed) : ""}
      </span>
    </button>
  );
}
