"use client";

import { Plus, Search } from "lucide-react";
import { useState } from "react";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import { exerciseKey } from "@/lib/gym";
import { formatDayLabel } from "@/lib/time";
import type { ExerciseDTO } from "@/lib/types";

/**
 * Picks an exercise, or names a new one.
 *
 * It's a search field over everything ever logged rather than a fixed catalogue:
 * the point is that typing "lat" surfaces the exact spelling used for the last
 * two years, so the history doesn't fracture across three near-identical names.
 * Anything not in the list can still be typed and created on the spot.
 */
export function ExercisePicker({
  open,
  onClose,
  exercises,
  onPick,
  /** Bubbles what was done here recently to the top of the empty-query list. */
  preferredIds = [],
}: {
  open: boolean;
  onClose: () => void;
  exercises: ExerciseDTO[];
  onPick: (choice: { exerciseId?: string; name: string }) => void;
  preferredIds?: string[];
}) {
  const [query, setQuery] = useState("");

  const q = query.trim().toLowerCase();
  const preferred = new Set(preferredIds);

  const matches = exercises
    .filter((e) => !e.archived || q)
    .filter((e) => !q || e.name.toLowerCase().includes(q))
    .sort((a, b) => {
      if (q) {
        // A name that starts with what was typed is almost always the one meant.
        const aStarts = a.name.toLowerCase().startsWith(q);
        const bStarts = b.name.toLowerCase().startsWith(q);
        if (aStarts !== bStarts) return aStarts ? -1 : 1;
      } else {
        const aPref = preferred.has(a.id);
        const bPref = preferred.has(b.id);
        if (aPref !== bPref) return aPref ? -1 : 1;
      }
      if (a.lastPerformed !== b.lastPerformed) {
        return (b.lastPerformed ?? "").localeCompare(a.lastPerformed ?? "");
      }
      return b.sessionCount - a.sessionCount;
    })
    .slice(0, 60);

  // Only offer to create when it isn't already there under that exact name.
  const canCreate =
    query.trim().length > 0 &&
    !exercises.some((e) => exerciseKey(e.name) === exerciseKey(query));

  function pick(choice: { exerciseId?: string; name: string }) {
    onPick(choice);
    onClose();
  }

  return (
    <Sheet open={open} onClose={onClose} title="Add exercise">
      <div className="flex flex-col gap-3">
        <div className="relative">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-faint" />
          <Input
            autoFocus
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key !== "Enter") return;
              e.preventDefault();
              if (matches.length > 0 && !canCreate) {
                pick({ exerciseId: matches[0].id, name: matches[0].name });
              } else if (canCreate) {
                pick({ name: query.trim() });
              }
            }}
            placeholder="Search or type a new name"
            className="pl-9"
          />
        </div>

        {canCreate && (
          <button
            type="button"
            onClick={() => pick({ name: query.trim() })}
            className="flex items-center gap-2 rounded-xl border border-dashed border-border px-3 py-2.5 text-left text-sm transition-colors hover:bg-surface-2"
          >
            <Plus className="h-4 w-4 shrink-0 text-primary" />
            <span className="min-w-0 truncate">
              Add <span className="font-medium">{query.trim()}</span>
            </span>
          </button>
        )}

        {matches.length === 0 && !canCreate ? (
          <p className="py-8 text-center text-xs text-faint">
            Nothing logged yet — type a name to start one.
          </p>
        ) : (
          <ul className="flex flex-col">
            {matches.map((exercise) => (
              <li key={exercise.id}>
                <button
                  type="button"
                  onClick={() => pick({ exerciseId: exercise.id, name: exercise.name })}
                  className="flex w-full items-center gap-3 rounded-lg px-1 py-2 text-left transition-colors hover:bg-surface-2"
                >
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-medium">{exercise.name}</p>
                    {exercise.lastRaw && (
                      <p className="truncate text-xs tabular-nums text-faint">
                        {exercise.lastRaw}
                      </p>
                    )}
                  </div>
                  <span className="shrink-0 text-xs text-faint">
                    {exercise.lastPerformed
                      ? formatDayLabel(exercise.lastPerformed)
                      : "new"}
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </Sheet>
  );
}
