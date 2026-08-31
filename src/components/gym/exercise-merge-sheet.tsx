"use client";

import { Check, GitMerge, Search } from "lucide-react";
import { useMemo, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import { mergeExercise } from "@/lib/client/use-gym";
import { cn } from "@/lib/cn";
import type { ExerciseDTO } from "@/lib/types";

export function ExerciseMergeSheet({
  source,
  exercises,
  onClose,
  onMerged,
}: {
  source: ExerciseDTO;
  exercises: ExerciseDTO[];
  onClose: () => void;
  onMerged: () => void;
}) {
  const [query, setQuery] = useState("");
  const [targetId, setTargetId] = useState<string | null>(null);
  const [isMerging, setIsMerging] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const targets = useMemo(() => {
    const q = query.trim().toLowerCase();
    return exercises
      .filter((exercise) => exercise.id !== source.id && !exercise.archived)
      .filter((exercise) => !q || exercise.name.toLowerCase().includes(q))
      .sort((left, right) => left.name.localeCompare(right.name));
  }, [exercises, query, source.id]);
  const target = exercises.find((exercise) => exercise.id === targetId) ?? null;

  async function submit() {
    if (!target || isMerging) return;
    setIsMerging(true);
    setError(null);
    try {
      await mergeExercise(source.id, target.id);
      onMerged();
    } catch (reason) {
      setError(reason instanceof Error ? reason.message : "Could not merge exercises");
      setIsMerging(false);
    }
  }

  return (
    <Sheet
      open
      onClose={onClose}
      title={`Merge “${source.name}”`}
      footer={
        target ? (
          <div>
            <p className="mb-3 text-xs leading-relaxed text-muted">
              All history moves to <strong className="text-foreground">{target.name}</strong>.
              The target name stays; {source.name} is removed. This cannot be undone.
            </p>
            {error && <p className="mb-3 text-xs text-red-500">{error}</p>}
            <Button className="w-full" onClick={submit} disabled={isMerging}>
              <GitMerge className="h-4 w-4" />
              {isMerging ? "Merging…" : `Merge into ${target.name}`}
            </Button>
          </div>
        ) : undefined
      }
    >
      <p className="mb-4 text-sm text-muted">
        Choose the exercise name you want to keep.
      </p>
      <div className="relative mb-3">
        <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-faint" />
        <Input
          autoFocus
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          placeholder="Search exercises"
          className="pl-9"
        />
      </div>

      {targets.length === 0 ? (
        <p className="py-10 text-center text-xs text-faint">No matching exercise.</p>
      ) : (
        <ul className="divide-y divide-border">
          {targets.map((exercise) => {
            const selected = exercise.id === targetId;
            return (
              <li key={exercise.id}>
                <button
                  type="button"
                  onClick={() => setTargetId(exercise.id)}
                  aria-pressed={selected}
                  className={cn(
                    "flex w-full items-center gap-3 py-3 text-left transition-colors",
                    selected ? "text-primary" : "hover:text-foreground",
                  )}
                >
                  <span className="min-w-0 flex-1">
                    <span className="block truncate text-sm font-medium">{exercise.name}</span>
                    <span className="block text-xs text-faint">
                      {exercise.sessionCount} session{exercise.sessionCount === 1 ? "" : "s"}
                    </span>
                  </span>
                  <span
                    className={cn(
                      "grid h-6 w-6 place-items-center rounded-full border",
                      selected ? "border-primary bg-primary text-primary-foreground" : "border-border",
                    )}
                    aria-hidden
                  >
                    {selected && <Check className="h-3.5 w-3.5" />}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </Sheet>
  );
}
