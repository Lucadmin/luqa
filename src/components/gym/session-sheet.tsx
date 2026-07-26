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
import { useEffect, useRef, useState } from "react";
import { ExerciseHistory } from "@/components/gym/exercise-history";
import { ExercisePicker } from "@/components/gym/exercise-picker";
import { SetInputList } from "@/components/gym/set-input";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import {
  createSession,
  deleteSession,
  patchSessionSilently,
  updateSession,
  type SessionInput,
} from "@/lib/client/use-gym";
import { cn } from "@/lib/cn";
import { parseSetLine, summarizeSets } from "@/lib/gym";
import { formatDayLabel } from "@/lib/time";
import type {
  ExerciseDTO,
  GymLocationDTO,
  GymSessionDTO,
  GymSetDTO,
} from "@/lib/types";

const AUTOSAVE_DELAY_MS = 600;

function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

interface Row {
  /** Stable across re-renders; exercises can repeat within a session. */
  key: string;
  exerciseId?: string;
  name: string;
  sets: GymSetDTO[];
  notes: string;
  showNotes: boolean;
  showHistory: boolean;
}

let rowSeq = 0;
function newRow(init: Partial<Row> & { name: string }): Row {
  return {
    key: `row-${rowSeq++}`,
    sets: [],
    notes: "",
    showNotes: false,
    showHistory: false,
    ...init,
  };
}

/**
 * Log a session — designed to just be left open on a phone at the gym.
 *
 * There is no save button that matters: opening on a blank session creates it
 * immediately, and every edit after that — a set, a note, a new exercise —
 * autosaves a moment later. Closing the sheet, backgrounding the app, or the
 * phone locking mid-set all flush whatever hasn't landed yet, so nothing is
 * ever lost between reps.
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
  const [sessionId, setSessionId] = useState<string | null>(null);
  const [pickerOpen, setPickerOpen] = useState(false);
  const [showNotesField, setShowNotesField] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [saveState, setSaveState] = useState<"saving" | "saved">("saved");

  // Whether this open created its own session (vs. editing one that already
  // existed) — only a session we started ourselves gets silently discarded
  // if it's closed empty.
  const eagerlyCreated = useRef(false);
  // Skips the autosave effect's very first run after (re)opening, which fires
  // from resetting form state rather than from a real edit.
  const hydrating = useRef(true);
  const saveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const dirty = useRef(false);

  // Re-arm the form each time it opens, from the session being edited or from
  // whatever was tapped to get here.
  const [wasOpen, setWasOpen] = useState(false);
  if (open !== wasOpen) {
    setWasOpen(open);
    if (open) {
      setError(null);
      setPickerOpen(false);
      if (session) {
        setSessionId(session.id);
        setDateKey(session.date);
        setLocationId(session.locationId);
        setNotes(session.notes);
        setShowNotesField(Boolean(session.notes));
        setRows(
          session.exercises.map((e) => {
            // Older entries can carry a remark the notation didn't capture
            // ("Nicht machen -> Knie broken"). Surface it as a note rather
            // than dropping it once editing moves it out of the raw line.
            const leftover =
              !e.notes && e.raw ? parseSetLine(e.raw).leftover : "";
            return newRow({
              exerciseId: e.exerciseId,
              name: e.name,
              sets: e.sets,
              notes: e.notes || leftover,
              showNotes: Boolean(e.notes || leftover),
            });
          }),
        );
      } else {
        setSessionId(null);
        setDateKey(todayKey());
        setLocationId(presetLocationId);
        setNotes("");
        setShowNotesField(false);
        setRows([]);
      }
    }
  }

  // The autosave bookkeeping (refs) resets alongside the form state above.
  // Refs can only be touched from an effect, not during render, so this runs
  // as a companion effect keyed to the same `open` transition.
  useEffect(() => {
    if (!open) return;
    hydrating.current = true;
    dirty.current = false;
    eagerlyCreated.current = false;
    if (saveTimer.current) {
      clearTimeout(saveTimer.current);
      saveTimer.current = null;
    }
  }, [open]);

  // Create the session the instant a blank sheet opens, so there's a real,
  // resumable record from the first tap rather than only on an eventual save.
  useEffect(() => {
    if (!open || sessionId || session) return;
    let cancelled = false;
    createSession({ date: dateKey, locationId, notes: "" })
      .then((created) => {
        if (cancelled) return;
        eagerlyCreated.current = true;
        setSessionId(created.id);
      })
      .catch((e) => {
        if (!cancelled) {
          setError(e instanceof Error ? e.message : "Could not start session");
        }
      });
    return () => {
      cancelled = true;
    };
    // Only the open/session/sessionId transition should trigger creation —
    // dateKey/locationId are read once at that moment, not re-triggered on
    // every subsequent edit (autosave carries those forward instead).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, session, sessionId]);

  function buildPayload(): SessionInput {
    return {
      date: dateKey,
      locationId,
      notes: notes.trim(),
      exercises: rows
        .filter((r) => r.name.trim())
        .map((r) => ({
          ...(r.exerciseId ? { exerciseId: r.exerciseId } : { name: r.name.trim() }),
          sets: r.sets,
          notes: r.notes.trim(),
        })),
    };
  }

  function flush(): Promise<unknown> {
    if (saveTimer.current) {
      clearTimeout(saveTimer.current);
      saveTimer.current = null;
    }
    if (!sessionId || !dirty.current) return Promise.resolve();
    dirty.current = false;
    setSaveState("saving");
    return patchSessionSilently(sessionId, buildPayload())
      .then(() => setSaveState("saved"))
      .catch(() => {
        dirty.current = true; // retry on the next edit, or the next close/hide
      });
  }

  // Debounced autosave: any edit reschedules a save a moment later, so rapid
  // typing doesn't fire a request per keystroke. The "saving" indicator flips
  // once the timer actually fires, not on every keystroke.
  useEffect(() => {
    if (!open) return;
    if (hydrating.current) {
      hydrating.current = false;
      return;
    }
    if (!sessionId) return; // creation still in flight; this effect re-runs once it resolves
    dirty.current = true;
    if (saveTimer.current) clearTimeout(saveTimer.current);
    saveTimer.current = setTimeout(() => {
      setSaveState("saving");
      void flush();
    }, AUTOSAVE_DELAY_MS);
    return () => {
      if (saveTimer.current) clearTimeout(saveTimer.current);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [dateKey, locationId, notes, rows, sessionId, open]);

  // Flush immediately when the tab/app is hidden — the realistic shape of
  // "closing the app" mid-set is backgrounding it, not a clean unmount. The
  // ref is kept current via its own effect, since refs can't be written
  // during render.
  const flushRef = useRef(flush);
  useEffect(() => {
    flushRef.current = flush;
  });
  useEffect(() => {
    if (!open) return;
    function onVisibilityChange() {
      if (document.hidden) void flushRef.current();
    }
    document.addEventListener("visibilitychange", onVisibilityChange);
    return () => document.removeEventListener("visibilitychange", onVisibilityChange);
  }, [open]);

  const exerciseById = new Map(exercises.map((e) => [e.id, e]));
  const activeLocations = locations.filter((l) => !l.archived || l.id === locationId);

  // The last session at the gym currently selected — the basis for "repeat".
  const lastHere = sessions.find(
    (s) =>
      s.id !== sessionId &&
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

  // Closing never blocks on the network: whatever's pending flushes and the
  // sheet dismisses right away. A session we started ourselves and left
  // completely empty is quietly discarded rather than left as clutter.
  function handleClose() {
    if (saveTimer.current) clearTimeout(saveTimer.current);
    if (sessionId) {
      const payload = buildPayload();
      const isEmpty = (payload.exercises?.length ?? 0) === 0 && !payload.notes;
      if (isEmpty && eagerlyCreated.current) {
        deleteSession(sessionId).catch(() => {});
      } else if (dirty.current) {
        dirty.current = false;
        updateSession(sessionId, payload).catch(() => {});
      }
    }
    onClose();
  }

  async function remove() {
    if (!sessionId) return;
    if (saveTimer.current) clearTimeout(saveTimer.current);
    dirty.current = false;
    setBusy(true);
    try {
      await deleteSession(sessionId);
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
        onClose={handleClose}
        title={
          <span className="flex items-center gap-2">
            Session
            <span className="text-xs font-normal text-faint">
              {!sessionId ? "Starting…" : saveState === "saving" ? "Saving…" : "Saved"}
            </span>
          </span>
        }
        footer={
          <div className="flex items-center gap-2">
            {sessionId && (
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
            <Button onClick={handleClose} disabled={busy} className="flex-1">
              Done
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
  const summary = summarizeSets(row.sets);

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

      <div className="mt-1.5">
        <SetInputList sets={row.sets} onChange={(sets) => onPatch({ sets })} />
      </div>

      {/* what's logged so far — never a blocker, just a read-out */}
      {summary && <p className="mt-1 text-[11px] text-faint">{summary}</p>}

      {/* last time, one tap away from being reused as a starting point */}
      {row.sets.length === 0 && exercise?.lastRaw && (
        <button
          type="button"
          onClick={() =>
            onPatch({ sets: parseSetLine(exercise.lastRaw ?? "").sets })
          }
          className="mt-1.5 flex w-full items-baseline gap-1.5 text-left text-[11px] text-faint transition-colors hover:text-foreground"
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
