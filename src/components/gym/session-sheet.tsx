"use client";

import {
  ChevronDown,
  LineChart,
  MessageSquarePlus,
  Plus,
  RotateCcw,
  Trash2,
  X,
} from "lucide-react";
import { useState } from "react";
import { ExerciseHistory } from "@/components/gym/exercise-history";
import { ExercisePicker } from "@/components/gym/exercise-picker";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import {
  createSession,
  deleteSession,
  updateSession,
} from "@/lib/client/use-gym";
import { cn } from "@/lib/cn";
import { parseSetLine, summarizeSets } from "@/lib/gym";
import { formatDayLabel } from "@/lib/time";
import type {
  ExerciseDTO,
  GymLocationDTO,
  GymSessionDTO,
} from "@/lib/types";

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

interface Row {
  /** Stable across re-renders; exercises can repeat within a session. */
  key: string;
  exerciseId?: string;
  name: string;
  raw: string;
  notes: string;
  showNotes: boolean;
  showHistory: boolean;
}

let rowSeq = 0;
function newRow(init: Partial<Row> & { name: string }): Row {
  return {
    key: `row-${rowSeq++}`,
    raw: "",
    notes: "",
    showNotes: false,
    showHistory: false,
    ...init,
  };
}

/**
 * Log a session.
 *
 * The whole design goal is that this never becomes homework: the date is
 * already right, the gym is one tap, and every exercise is a single free-text
 * line in the notation the user already writes by hand. Structure is read out
 * of that line — it is never demanded up front.
 */
export function SessionSheet({
  open,
  onClose,
  session = null,
  locations,
  exercises,
  sessions,
  presetLocationId = null,
  onManageLocations,
}: {
  open: boolean;
  onClose: () => void;
  session?: GymSessionDTO | null;
  locations: GymLocationDTO[];
  exercises: ExerciseDTO[];
  /** Recent sessions, used to repeat the last one at a gym. */
  sessions: GymSessionDTO[];
  presetLocationId?: string | null;
  onManageLocations: () => void;
}) {
  const [dateKey, setDateKey] = useState(todayKey());
  const [locationId, setLocationId] = useState<string | null>(null);
  const [notes, setNotes] = useState("");
  const [rows, setRows] = useState<Row[]>([]);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [showNotesField, setShowNotesField] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  // Re-arm the form each time it opens, from the session being edited or from
  // whatever was tapped to get here.
  const [wasOpen, setWasOpen] = useState(false);
  if (open !== wasOpen) {
    setWasOpen(open);
    if (open) {
      setError(null);
      setPickerOpen(false);
      if (session) {
        setDateKey(session.date);
        setLocationId(session.locationId);
        setNotes(session.notes);
        setShowNotesField(Boolean(session.notes));
        setRows(
          session.exercises.map((e) =>
            newRow({
              exerciseId: e.exerciseId,
              name: e.name,
              raw: e.raw,
              notes: e.notes,
              showNotes: Boolean(e.notes),
            }),
          ),
        );
      } else {
        setDateKey(todayKey());
        setLocationId(presetLocationId);
        setNotes("");
        setShowNotesField(false);
        setRows([]);
      }
    }
  }

  const exerciseById = new Map(exercises.map((e) => [e.id, e]));
  const activeLocations = locations.filter((l) => !l.archived || l.id === locationId);

  // The last session at the gym currently selected — the basis for "repeat".
  const lastHere = sessions.find(
    (s) =>
      s.id !== session?.id &&
      s.exercises.length > 0 &&
      (locationId ? s.locationId === locationId : true),
  );

  function patchRow(key: string, patch: Partial<Row>) {
    setRows((current) =>
      current.map((r) => (r.key === key ? { ...r, ...patch } : r)),
    );
  }

  function removeRow(key: string) {
    setRows((current) => current.filter((r) => r.key !== key));
  }

  function repeatLast() {
    if (!lastHere) return;
    // Names and order come back; the numbers stay empty so last time's values
    // are a target to beat rather than something to correct.
    setRows(
      lastHere.exercises.map((e) =>
        newRow({ exerciseId: e.exerciseId, name: e.name }),
      ),
    );
  }

  async function save() {
    setBusy(true);
    setError(null);
    try {
      const payload = {
        date: dateKey,
        locationId,
        notes: notes.trim(),
        exercises: rows
          .filter((r) => r.name.trim())
          .map((r) => ({
            ...(r.exerciseId ? { exerciseId: r.exerciseId } : { name: r.name.trim() }),
            raw: r.raw.trim(),
            notes: r.notes.trim(),
          })),
      };

      if (session) await updateSession(session.id, payload);
      else await createSession(payload);

      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save");
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!session) return;
    setBusy(true);
    try {
      await deleteSession(session.id);
      onClose();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not delete");
    } finally {
      setBusy(false);
    }
  }

  return (
    <>
      <Sheet
        open={open}
        onClose={onClose}
        title={session ? "Session" : "New session"}
        footer={
          <div className="flex items-center gap-2">
            {session && (
              <Button
                variant="ghost"
                size="icon"
                onClick={remove}
                disabled={busy}
                aria-label="Delete session"
                className="text-red-500 hover:bg-red-500/10 hover:text-red-500"
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            )}
            <Button onClick={save} disabled={busy} className="flex-1">
              {busy ? "Saving…" : "Save"}
            </Button>
          </div>
        }
      >
        <div className="flex flex-col gap-4">
          {error && <p className="text-sm text-red-500">{error}</p>}

          {/* when and where */}
          <div className="flex flex-col gap-2">
            <Input
              type="date"
              value={dateKey}
              onChange={(e) => setDateKey(e.target.value || todayKey())}
              className="h-10"
            />

            <div className="flex flex-wrap gap-1.5">
              {activeLocations.map((l) => (
                <button
                  key={l.id}
                  type="button"
                  onClick={() => setLocationId(locationId === l.id ? null : l.id)}
                  title={l.name}
                  className={cn(
                    "rounded-full border px-3 py-1.5 text-xs font-medium transition-colors",
                    locationId === l.id
                      ? "border-transparent text-white"
                      : "border-border text-muted hover:bg-surface-2",
                  )}
                  style={
                    locationId === l.id ? { backgroundColor: l.color } : undefined
                  }
                >
                  {l.code}
                </button>
              ))}
              <button
                type="button"
                onClick={onManageLocations}
                className="rounded-full border border-dashed border-border px-3 py-1.5 text-xs font-medium text-faint transition-colors hover:bg-surface-2"
              >
                <Plus className="mr-0.5 inline h-3 w-3" />
                Gym
              </button>
            </div>
          </div>

          {/* exercises */}
          <div className="flex flex-col gap-2">
            {rows.map((row) => (
              <ExerciseRow
                key={row.key}
                row={row}
                exercise={row.exerciseId ? exerciseById.get(row.exerciseId) : undefined}
                locations={locations}
                locationId={locationId}
                onPatch={(patch) => patchRow(row.key, patch)}
                onRemove={() => removeRow(row.key)}
              />
            ))}

            <div className="flex gap-2">
              <button
                type="button"
                onClick={() => setPickerOpen(true)}
                className="flex flex-1 items-center justify-center gap-1.5 rounded-xl border border-dashed border-border py-2.5 text-sm font-medium text-muted transition-colors hover:bg-surface-2"
              >
                <Plus className="h-4 w-4" />
                Add exercise
              </button>

              {rows.length === 0 && lastHere && (
                <button
                  type="button"
                  onClick={repeatLast}
                  title={`Same exercises as ${formatDayLabel(lastHere.date)}`}
                  className="flex items-center gap-1.5 rounded-xl border border-dashed border-border px-3 py-2.5 text-sm font-medium text-muted transition-colors hover:bg-surface-2"
                >
                  <RotateCcw className="h-4 w-4" />
                  Repeat last
                </button>
              )}
            </div>
          </div>

          {/* how the session felt */}
          {showNotesField ? (
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              rows={2}
              placeholder="How it went — energy, niggles, anything worth knowing next time"
              className="w-full rounded-xl border border-border bg-surface px-3.5 py-2.5 text-sm placeholder:text-faint focus-visible:border-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/30"
            />
          ) : (
            <button
              type="button"
              onClick={() => setShowNotesField(true)}
              className="flex items-center gap-1.5 self-start text-xs font-medium text-faint transition-colors hover:text-foreground"
            >
              <MessageSquarePlus className="h-3.5 w-3.5" />
              Add a note about the session
            </button>
          )}
        </div>
      </Sheet>

      <ExercisePicker
        open={pickerOpen}
        onClose={() => setPickerOpen(false)}
        exercises={exercises}
        preferredIds={lastHere?.exercises.map((e) => e.exerciseId) ?? []}
        onPick={(choice) =>
          setRows((current) => [
            ...current,
            newRow({ exerciseId: choice.exerciseId, name: choice.name }),
          ])
        }
      />
    </>
  );
}

function ExerciseRow({
  row,
  exercise,
  locations,
  locationId,
  onPatch,
  onRemove,
}: {
  row: Row;
  exercise?: ExerciseDTO;
  locations: GymLocationDTO[];
  locationId: string | null;
  onPatch: (patch: Partial<Row>) => void;
  onRemove: () => void;
}) {
  const parsed = parseSetLine(row.raw);
  const summary = summarizeSets(parsed.sets);

  const lastGym = exercise?.lastLocationId
    ? locations.find((l) => l.id === exercise.lastLocationId)
    : null;

  return (
    <div className="rounded-2xl border border-border bg-surface px-3 py-2.5">
      <div className="flex items-center gap-1">
        <p className="min-w-0 flex-1 truncate text-sm font-medium">{row.name}</p>

        <button
          type="button"
          onClick={() => onPatch({ showNotes: !row.showNotes })}
          aria-label="Note"
          className={cn(
            "grid h-7 w-7 place-items-center rounded-lg transition-colors hover:bg-surface-2",
            row.notes ? "text-primary" : "text-faint hover:text-foreground",
          )}
        >
          <MessageSquarePlus className="h-3.5 w-3.5" />
        </button>

        {exercise && (
          <button
            type="button"
            onClick={() => onPatch({ showHistory: !row.showHistory })}
            aria-label="History"
            aria-expanded={row.showHistory}
            className={cn(
              "grid h-7 w-7 place-items-center rounded-lg transition-colors hover:bg-surface-2",
              row.showHistory ? "text-primary" : "text-faint hover:text-foreground",
            )}
          >
            {row.showHistory ? (
              <ChevronDown className="h-3.5 w-3.5" />
            ) : (
              <LineChart className="h-3.5 w-3.5" />
            )}
          </button>
        )}

        <button
          type="button"
          onClick={onRemove}
          aria-label={`Remove ${row.name}`}
          className="grid h-7 w-7 place-items-center rounded-lg text-faint transition-colors hover:bg-surface-2 hover:text-red-500"
        >
          <X className="h-3.5 w-3.5" />
        </button>
      </div>

      <input
        value={row.raw}
        onChange={(e) => onPatch({ raw: e.target.value })}
        inputMode="text"
        placeholder={exercise?.lastRaw || "40-10 57-10 77-8 77-8"}
        className="mt-1 w-full bg-transparent text-sm tabular-nums placeholder:text-faint/60 focus:outline-none"
      />

      {/* what the app made of the line — never a blocker, just a read-out */}
      {(summary || parsed.leftover) && (
        <p className="mt-0.5 text-[11px] text-faint">
          {summary}
          {summary && parsed.leftover && " · "}
          {parsed.leftover && (
            <span className="italic">{parsed.leftover}</span>
          )}
        </p>
      )}

      {/* last time, one tap away from being reused */}
      {!row.raw && exercise?.lastRaw && (
        <button
          type="button"
          onClick={() => onPatch({ raw: exercise.lastRaw ?? "" })}
          className="mt-1 flex w-full items-baseline gap-1.5 text-left text-[11px] text-faint transition-colors hover:text-foreground"
        >
          <RotateCcw className="h-3 w-3 shrink-0" />
          <span className="min-w-0 flex-1 truncate tabular-nums">
            {exercise.lastRaw}
          </span>
          <span className="shrink-0">
            {lastGym && lastGym.id !== locationId ? `${lastGym.code} · ` : ""}
            {exercise.lastPerformed ? formatDayLabel(exercise.lastPerformed) : ""}
          </span>
        </button>
      )}

      {row.showNotes && (
        <input
          value={row.notes}
          onChange={(e) => onPatch({ notes: e.target.value })}
          placeholder="Note for this exercise"
          className="mt-1.5 w-full rounded-lg bg-surface-2 px-2.5 py-1.5 text-xs placeholder:text-faint focus:outline-none"
        />
      )}

      {row.showHistory && exercise && (
        <div className="mt-3 border-t border-border pt-3">
          <ExerciseHistory
            exerciseId={exercise.id}
            locations={locations}
            defaultLocationId={locationId}
            compact
          />
        </div>
      )}
    </div>
  );
}
