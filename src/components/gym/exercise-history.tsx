"use client";

import { Trophy } from "lucide-react";
import { useState } from "react";
import {
  MetricTabs,
  ProgressChart,
  type Metric,
} from "@/components/gym/progress-chart";
import { Sheet } from "@/components/ui/sheet";
import { useExerciseHistory } from "@/lib/client/use-gym";
import { cn } from "@/lib/cn";
import { formatWeight, summarizeSets } from "@/lib/gym";
import { formatDayLabel } from "@/lib/time";
import type { GymLocationDTO } from "@/lib/types";

/**
 * What this exercise has done over time.
 *
 * The gym filter is the important control here. Weight stacks aren't
 * comparable between gyms — 70 on one machine is a different lift than 70 on
 * another — so the panel opens filtered to the gym being logged at, and
 * switching to "All gyms" is one tap when the comparison does make sense.
 */
export function ExerciseHistory({
  exerciseId,
  locations,
  defaultLocationId = null,
  compact = false,
}: {
  exerciseId: string;
  locations: GymLocationDTO[];
  defaultLocationId?: string | null;
  compact?: boolean;
}) {
  const [locationId, setLocationId] = useState<string | null>(defaultLocationId);
  const [metric, setMetric] = useState<Metric>("estimated");

  const { history, isLoading } = useExerciseHistory(exerciseId, locationId);

  // Only gyms this exercise has actually been done at are worth offering.
  const seen = history?.exercise.locationIds ?? [];
  const options = locations.filter(
    (l) => seen.includes(l.id) || l.id === defaultLocationId,
  );
  const showFilter = options.length > 1 || (options.length === 1 && seen.length > 0);

  const points = history?.points ?? [];
  const recent = [...points].reverse();

  return (
    <div className="flex flex-col gap-3">
      {showFilter && (
        <div className="flex flex-wrap gap-1">
          <FilterChip
            active={locationId === null}
            onClick={() => setLocationId(null)}
            label="All gyms"
          />
          {options.map((l) => (
            <FilterChip
              key={l.id}
              active={locationId === l.id}
              onClick={() => setLocationId(l.id)}
              label={l.code}
              title={l.name}
            />
          ))}
        </div>
      )}

      {isLoading && !history ? (
        <div className="h-[108px] animate-pulse rounded-xl bg-surface-2" />
      ) : points.length === 0 ? (
        <p className="rounded-xl border border-dashed border-border px-3 py-6 text-center text-xs text-faint">
          {locationId
            ? "Never done at this gym yet."
            : "First time — nothing to compare against."}
        </p>
      ) : (
        <>
          <MetricTabs metric={metric} onChange={setMetric} />
          <ProgressChart points={points} metric={metric} />

          <div className="grid grid-cols-2 gap-2">
            <Stat
              label="Best est. 1RM"
              value={history?.bestEver !== null && history?.bestEver !== undefined
                ? formatWeight(history.bestEver)
                : "—"}
            />
            <Stat
              label="Heaviest"
              value={history?.heaviest !== null && history?.heaviest !== undefined
                ? formatWeight(history.heaviest)
                : "—"}
            />
          </div>

          <div>
            <p className="text-xs font-medium uppercase tracking-wide text-faint">
              Last times
            </p>
            <ul className="mt-1 divide-y divide-border">
              {recent.slice(0, compact ? 3 : 25).map((point) => (
                <li key={point.sessionId} className="py-2">
                  <div className="flex items-baseline gap-2">
                    <span className="w-14 shrink-0 text-xs tabular-nums text-faint">
                      {formatDayLabel(point.date)}
                    </span>
                    <p className="min-w-0 flex-1 text-sm tabular-nums">
                      {point.raw || summarizeSets(point.sets) || "—"}
                    </p>
                    {point.isPr && (
                      <Trophy
                        className="h-3.5 w-3.5 shrink-0 text-amber-500"
                        aria-label="Personal record"
                      />
                    )}
                  </div>
                  {point.notes && (
                    <p className="mt-0.5 pl-16 text-xs text-faint">{point.notes}</p>
                  )}
                </li>
              ))}
            </ul>
          </div>
        </>
      )}
    </div>
  );
}

function FilterChip({
  active,
  onClick,
  label,
  title,
}: {
  active: boolean;
  onClick: () => void;
  label: string;
  title?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      title={title}
      className={cn(
        "rounded-full border px-2.5 py-1 text-xs font-medium transition-colors",
        active
          ? "border-primary bg-primary/10 text-primary"
          : "border-border text-muted hover:bg-surface-2",
      )}
    >
      {label}
    </button>
  );
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border px-3 py-2">
      <p className="text-[10px] font-medium uppercase tracking-wide text-faint">
        {label}
      </p>
      <p className="mt-0.5 text-sm font-semibold tabular-nums">{value}</p>
    </div>
  );
}

/** The same panel as a standalone sheet, opened from a session row. */
export function ExerciseHistorySheet({
  exerciseId,
  name,
  locations,
  defaultLocationId = null,
  onClose,
}: {
  exerciseId: string | null;
  name: string;
  locations: GymLocationDTO[];
  defaultLocationId?: string | null;
  onClose: () => void;
}) {
  return (
    <Sheet open={exerciseId !== null} onClose={onClose} title={name}>
      {exerciseId && (
        <ExerciseHistory
          exerciseId={exerciseId}
          locations={locations}
          defaultLocationId={defaultLocationId}
        />
      )}
    </Sheet>
  );
}
