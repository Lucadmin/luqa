"use client";

import { Dumbbell, MapPin, Plus, Search } from "lucide-react";
import { useState } from "react";
import { ExerciseHistorySheet } from "@/components/gym/exercise-history";
import { LocationsSheet } from "@/components/gym/locations-sheet";
import { SessionSheet } from "@/components/gym/session-sheet";
import { Input } from "@/components/ui/input";
import { useGymOverview } from "@/lib/client/use-gym";
import { cn } from "@/lib/cn";
import { formatDayLabel } from "@/lib/time";
import type { ExerciseDTO, GymSessionDTO } from "@/lib/types";

type Tab = "sessions" | "exercises";

export function GymView() {
  const { overview, isLoading } = useGymOverview();

  const [tab, setTab] = useState<Tab>("sessions");
  const [sessionOpen, setSessionOpen] = useState(false);
  const [editing, setEditing] = useState<GymSessionDTO | null>(null);
  const [locationsOpen, setLocationsOpen] = useState(false);
  const [historyId, setHistoryId] = useState<string | null>(null);
  const [query, setQuery] = useState("");

  const locations = overview?.locations ?? [];
  const exercises = overview?.exercises ?? [];
  const sessions = overview?.sessions ?? [];
  const locationById = new Map(locations.map((l) => [l.id, l]));

  function newSession() {
    setEditing(null);
    setSessionOpen(true);
  }

  function editSession(session: GymSessionDTO) {
    setEditing(session);
    setSessionOpen(true);
  }

  const q = query.trim().toLowerCase();
  const shownExercises = exercises
    .filter((e) => !e.archived)
    .filter((e) => !q || e.name.toLowerCase().includes(q))
    .sort((a, b) => {
      if (a.lastPerformed !== b.lastPerformed) {
        return (b.lastPerformed ?? "").localeCompare(a.lastPerformed ?? "");
      }
      return b.sessionCount - a.sessionCount;
    });

  const historyExercise = historyId
    ? exercises.find((e) => e.id === historyId)
    : null;

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 md:px-8 md:py-7">
      <div className="flex items-center justify-between gap-3">
        <h1 className="text-xl font-semibold tracking-tight">Gym</h1>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => setLocationsOpen(true)}
            aria-label="Gyms"
            className="grid h-9 w-9 place-items-center rounded-full text-muted hover:bg-surface-2 hover:text-foreground"
          >
            <MapPin className="h-4.5 w-4.5" />
          </button>
          <button
            type="button"
            onClick={newSession}
            aria-label="New session"
            className="grid h-9 w-9 place-items-center rounded-full bg-primary text-primary-foreground shadow-sm transition-colors hover:bg-primary-hover"
          >
            <Plus className="h-4.5 w-4.5" />
          </button>
        </div>
      </div>

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
          {isLoading && sessions.length === 0 ? (
            <div className="flex flex-col gap-2">
              {[0, 1, 2].map((i) => (
                <div key={i} className="h-16 animate-pulse rounded-2xl bg-surface-2" />
              ))}
            </div>
          ) : sessions.length === 0 ? (
            <EmptyState onCreate={newSession} />
          ) : (
            <ul className="flex flex-col gap-1.5">
              {sessions.map((session) => (
                <li key={session.id}>
                  <SessionRow
                    session={session}
                    location={session.locationId ? locationById.get(session.locationId) : undefined}
                    onOpen={() => editSession(session)}
                  />
                </li>
              ))}
            </ul>
          )}
        </div>
      ) : (
        <div className="mt-4">
          {exercises.length > 0 && (
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

      <SessionSheet
        open={sessionOpen}
        onClose={() => setSessionOpen(false)}
        session={editing}
        locations={locations}
        exercises={exercises}
        sessions={sessions}
        onManageLocations={() => setLocationsOpen(true)}
      />

      <LocationsSheet
        open={locationsOpen}
        onClose={() => setLocationsOpen(false)}
        locations={locations}
      />

      <ExerciseHistorySheet
        exerciseId={historyId}
        name={historyExercise?.name ?? ""}
        locations={locations}
        onClose={() => setHistoryId(null)}
      />
    </div>
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

  return (
    <button
      type="button"
      onClick={onOpen}
      className="flex w-full items-center gap-3 rounded-2xl border border-border bg-surface px-3.5 py-3 text-left transition-colors hover:bg-surface-2"
    >
      <div className="flex w-14 shrink-0 flex-col items-center">
        <span className="text-xs font-medium tabular-nums text-faint">
          {formatDayLabel(session.date)}
        </span>
      </div>

      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-medium">
          {preview || "No exercises logged"}
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

function EmptyState({ onCreate }: { onCreate: () => void }) {
  return (
    <div className="flex flex-col items-center gap-3 rounded-2xl border border-dashed border-border py-14 text-center">
      <span className="grid h-12 w-12 place-items-center rounded-2xl bg-primary/10 text-primary">
        <Dumbbell className="h-6 w-6" />
      </span>
      <div>
        <p className="text-sm font-medium">No sessions yet</p>
        <p className="mt-0.5 text-xs text-faint">
          Log today&apos;s and the history builds itself from there.
        </p>
      </div>
      <button
        type="button"
        onClick={onCreate}
        className="mt-1 inline-flex items-center gap-1.5 rounded-full bg-primary px-4 py-2 text-sm font-medium text-primary-foreground hover:bg-primary-hover"
      >
        <Plus className="h-4 w-4" />
        Log a session
      </button>
    </div>
  );
}
