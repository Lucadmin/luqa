"use client";

import { CalendarHeart, Layers, Maximize2, ZoomIn, ZoomOut } from "lucide-react";
import { useMemo, useState } from "react";
import { LifeGrid } from "@/components/life/life-grid";
import { PeriodsSheet } from "@/components/life/periods-sheet";
import { WeekNoteSheet } from "@/components/life/week-note-sheet";
import { Button } from "@/components/ui/button";
import { apiSend } from "@/lib/client/fetcher";
import { useLife } from "@/lib/client/use-life";
import { useNow } from "@/lib/client/use-now";
import {
  buildCellColors,
  lifeStats,
  type PeriodRange,
  toDateKey,
  totalWeeks,
  WEEKS_PER_YEAR,
  weekIndexFor,
  weekStartUtc,
} from "@/lib/life";
import type { WeekNoteDTO } from "@/lib/types";

const ZOOM_MIN = 1;
const ZOOM_MAX = 6;
const ZOOM_STEP = 0.5;

function fmtUtc(ms: number): string {
  return new Date(ms).toLocaleDateString(undefined, {
    day: "numeric",
    month: "short",
    year: "numeric",
    timeZone: "UTC",
  });
}

function EmptyState({ onSaved }: { onSaved: () => void }) {
  const [date, setDate] = useState("");
  const [busy, setBusy] = useState(false);

  async function save() {
    if (!date) return;
    setBusy(true);
    try {
      await apiSend("/api/settings", "PATCH", { birthDate: date });
      onSaved();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="grid h-full place-items-center p-6">
      <div className="w-full max-w-sm rounded-2xl border border-border bg-surface p-6 text-center">
        <div className="mx-auto grid h-12 w-12 place-items-center rounded-xl bg-surface-2">
          <CalendarHeart className="h-6 w-6 text-primary" />
        </div>
        <h2 className="mt-4 text-base font-semibold">Your life in weeks</h2>
        <p className="mt-1 text-sm text-muted">
          Every week of your life as a single square. Set your date of birth to
          begin.
        </p>
        <input
          type="date"
          value={date}
          max={new Date().toISOString().slice(0, 10)}
          onChange={(e) => setDate(e.target.value)}
          className="mt-4 h-11 w-full rounded-xl border border-border bg-surface px-3.5 text-sm tabular-nums focus-visible:outline-none focus-visible:border-primary"
        />
        <Button onClick={save} disabled={!date || busy} className="mt-3 w-full">
          {busy ? "Saving…" : "Show my life"}
        </Button>
      </div>
    </div>
  );
}

export function LifeView() {
  const { life, isLoading, mutate, createPeriod, updatePeriod, deletePeriod, saveNote } =
    useLife();

  const [zoom, setZoom] = useState(1);
  const [selectedWeek, setSelectedWeek] = useState<number | null>(null);
  const [periodsOpen, setPeriodsOpen] = useState(false);

  const setZoomClamped = (z: number) =>
    setZoom(Math.min(ZOOM_MAX, Math.max(ZOOM_MIN, Math.round(z * 100) / 100)));

  const birthKey = life.birthDate;
  const years = life.lifeExpectancyYears;
  // Captured once at mount (no ticking) — the current week only changes daily.
  const now = useNow(false);

  const derived = useMemo(() => {
    if (!birthKey) return null;
    const todayKey = toDateKey(now);
    const total = totalWeeks(years);
    const stats = lifeStats(birthKey, years, todayKey);

    const ranges: PeriodRange[] = life.periods.map((p) => ({
      color: p.color,
      startWeek: weekIndexFor(birthKey, p.startDate),
      // Ongoing periods run up to the current week.
      endWeek: p.endDate ? weekIndexFor(birthKey, p.endDate) : stats.currentWeek,
    }));
    const cellColors = buildCellColors(ranges, total);

    const notesByIndex = new Map<number, WeekNoteDTO>();
    const noteWeeks = new Set<number>();
    const milestoneWeeks = new Set<number>();
    for (const n of life.notes) {
      notesByIndex.set(n.weekIndex, n);
      noteWeeks.add(n.weekIndex);
      if (n.milestone) milestoneWeeks.add(n.weekIndex);
    }

    return { total, stats, cellColors, notesByIndex, noteWeeks, milestoneWeeks };
  }, [birthKey, years, life.periods, life.notes, now]);

  const labelFor = useMemo(() => {
    return (i: number) => {
      if (!birthKey) return "";
      const start = weekStartUtc(birthKey, i);
      const age = Math.floor(i / WEEKS_PER_YEAR);
      return `Age ${age} · week ${(i % WEEKS_PER_YEAR) + 1} — ${fmtUtc(start)}`;
    };
  }, [birthKey]);

  if (isLoading && !birthKey) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-40 w-full max-w-3xl animate-pulse rounded-2xl bg-surface-2" />
      </div>
    );
  }

  if (!birthKey || !derived) {
    return <EmptyState onSaved={() => mutate()} />;
  }

  const { stats, cellColors, notesByIndex, noteWeeks, milestoneWeeks } = derived;

  const selectedNote =
    selectedWeek !== null ? notesByIndex.get(selectedWeek) : undefined;

  const selectedPeriodNames =
    selectedWeek !== null
      ? life.periods
          .filter((p) => {
            const s = weekIndexFor(birthKey, p.startDate);
            const e = p.endDate ? weekIndexFor(birthKey, p.endDate) : stats.currentWeek;
            return selectedWeek >= s && selectedWeek <= e;
          })
          .map((p) => p.name)
      : [];

  const selectedHeadline =
    selectedWeek !== null
      ? `Age ${Math.floor(selectedWeek / WEEKS_PER_YEAR)}, week ${(selectedWeek % WEEKS_PER_YEAR) + 1}`
      : "";
  const selectedRange =
    selectedWeek !== null
      ? `${fmtUtc(weekStartUtc(birthKey, selectedWeek))} – ${fmtUtc(
          weekStartUtc(birthKey, selectedWeek) + 6 * 86_400_000,
        )}`
      : "";

  return (
    <div className="flex h-full flex-col">
      {/* Compact toolbar */}
      <div className="flex shrink-0 items-center gap-2 border-b border-border px-3 py-1.5">
        <p className="min-w-0 flex-1 truncate text-xs text-muted">
          <span className="font-medium text-foreground">
            {stats.years}y {stats.weeksIntoYear}w
          </span>{" "}
          lived · {Math.round(stats.fractionLived * 100)}% ·{" "}
          {stats.weeksRemaining.toLocaleString()} left
        </p>
        <div className="flex shrink-0 items-center rounded-lg border border-border">
          <button
            type="button"
            aria-label="Zoom out"
            onClick={() => setZoomClamped(zoom - ZOOM_STEP)}
            disabled={zoom <= ZOOM_MIN}
            className="grid h-7 w-7 place-items-center rounded-l-lg text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <ZoomOut className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            aria-label="Fit to screen"
            onClick={() => setZoom(1)}
            className="grid h-7 w-7 place-items-center border-x border-border text-muted hover:bg-surface-2 hover:text-foreground"
          >
            <Maximize2 className="h-3 w-3" />
          </button>
          <button
            type="button"
            aria-label="Zoom in"
            onClick={() => setZoomClamped(zoom + ZOOM_STEP)}
            disabled={zoom >= ZOOM_MAX}
            className="grid h-7 w-7 place-items-center rounded-r-lg text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <ZoomIn className="h-3.5 w-3.5" />
          </button>
        </div>
        <button
          type="button"
          aria-label="Life periods"
          onClick={() => setPeriodsOpen(true)}
          className="grid h-7 w-7 shrink-0 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground"
        >
          <Layers className="h-3.5 w-3.5" />
        </button>
      </div>

      {/* Grid */}
      <div className="min-h-0 flex-1 p-2 md:p-4">
        <LifeGrid
          totalWeeks={derived.total}
          currentWeek={stats.currentWeek}
          cellColors={cellColors}
          noteWeeks={noteWeeks}
          milestoneWeeks={milestoneWeeks}
          zoom={zoom}
          onZoomChange={setZoomClamped}
          selectedWeek={selectedWeek}
          onSelect={setSelectedWeek}
          labelFor={labelFor}
        />
      </div>

      <WeekNoteSheet
        weekIndex={selectedWeek}
        note={selectedNote}
        headline={selectedHeadline}
        dateRange={selectedRange}
        periodNames={selectedPeriodNames}
        onClose={() => setSelectedWeek(null)}
        onSave={saveNote}
      />

      <PeriodsSheet
        open={periodsOpen}
        onClose={() => setPeriodsOpen(false)}
        periods={life.periods}
        onCreate={createPeriod}
        onUpdate={updatePeriod}
        onDelete={deletePeriod}
      />
    </div>
  );
}
