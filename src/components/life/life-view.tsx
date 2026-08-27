"use client";

import { CalendarHeart, Layers, RefreshCw } from "lucide-react";
import dynamic from "next/dynamic";
import { useMemo, useRef, useState } from "react";
import { LifeWall, type LifeWallHandle } from "@/components/life/life-wall";
import { WeekFilmstrip } from "@/components/life/week-filmstrip";
import { Button } from "@/components/ui/button";
import { apiSend } from "@/lib/client/fetcher";
import { useLife } from "@/lib/client/use-life";
import { useNow } from "@/lib/client/use-now";
import { useSettings } from "@/lib/client/use-settings";
import {
  buildCellPeriods,
  lifeStats,
  type PeriodRange,
  totalWeeks,
  WEEKS_PER_YEAR,
  weekEndUtc,
  weekIndexFor,
  weekStartUtc,
} from "@/lib/life";
import { isoDateKey, startOfViewDay } from "@/lib/time";
import type { WeekNoteDTO } from "@/lib/types";

// Modals only matter once opened — load them on demand instead of paying
// for their JS on every visit to the life tab.
const PeriodsSheet = dynamic(() =>
  import("@/components/life/periods-sheet").then((m) => m.PeriodsSheet),
);
const WeekReviewPanel = dynamic(() =>
  import("@/components/life/week-review-panel").then((m) => m.WeekReviewPanel),
);

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
        <label className="mt-4 block text-left">
          <span className="mb-1.5 block text-xs font-medium text-muted">
            Date of birth
          </span>
          <input
            type="date"
            value={date}
            max={new Date().toISOString().slice(0, 10)}
            onChange={(e) => setDate(e.target.value)}
            className="h-11 w-full rounded-xl border border-border bg-surface px-3.5 text-sm tabular-nums focus-visible:border-primary focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring/30"
          />
        </label>
        <Button onClick={save} disabled={!date || busy} className="mt-3 w-full">
          {busy ? "Saving…" : "Show my life"}
        </Button>
      </div>
    </div>
  );
}

export function LifeView() {
  const {
    life,
    isLoading,
    error,
    mutate,
    createPeriod,
    updatePeriod,
    deletePeriod,
    saveNote,
  } = useLife();
  const { settings } = useSettings();
  const { dayStartHour } = settings;

  const [openWeek, setOpenWeek] = useState<number | null>(null);
  const [jump, setJump] = useState<{ week: number; token: number } | null>(null);
  const [periodsOpen, setPeriodsOpen] = useState(false);
  const wallRef = useRef<LifeWallHandle>(null);

  const birthKey = life.birthDate;
  const years = life.lifeExpectancyYears;
  // Captured once at mount (no ticking) — the current week only changes daily.
  const now = useNow(false);

  const derived = useMemo(() => {
    if (!birthKey) return null;
    // Local calendar day, not UTC — matches the logical-day cutoff used
    // everywhere else (habits, timeline). Using UTC here made the birthday
    // row flip a few hours early or late for anyone outside UTC.
    const todayKey = isoDateKey(startOfViewDay(new Date(now), dayStartHour));
    const total = totalWeeks(years);
    const stats = lifeStats(birthKey, years, todayKey);

    const ranges: PeriodRange[] = life.periods.map((p) => ({
      id: p.id,
      name: p.name,
      color: p.color,
      startWeek: weekIndexFor(birthKey, p.startDate),
      // Ongoing periods run up to the current week.
      endWeek: p.endDate ? weekIndexFor(birthKey, p.endDate) : stats.currentWeek,
    }));
    const cellPeriods = buildCellPeriods(ranges, total);

    const notesByIndex = new Map<number, WeekNoteDTO>();
    const noteWeeks = new Set<number>();
    const milestoneWeeks = new Set<number>();
    for (const n of life.notes) {
      notesByIndex.set(n.weekIndex, n);
      noteWeeks.add(n.weekIndex);
      if (n.milestone) milestoneWeeks.add(n.weekIndex);
    }

    return { total, stats, cellPeriods, notesByIndex, noteWeeks, milestoneWeeks };
  }, [birthKey, years, life.periods, life.notes, now, dayStartHour]);

  const labelFor = useMemo(() => {
    return (i: number) => {
      if (!birthKey) return "";
      const start = weekStartUtc(birthKey, i);
      const age = Math.floor(i / WEEKS_PER_YEAR);
      const week = i % WEEKS_PER_YEAR;
      return week === 0
        ? `Birthday · age ${age} — ${fmtUtc(start)}`
        : `Age ${age} · week ${week + 1} — ${fmtUtc(start)}`;
    };
  }, [birthKey]);

  // Shorter label for the wall's drag magnifier — names of any overlapping
  // periods matter more there than the exact date range.
  const magnifierLabelFor = useMemo(() => {
    return (i: number) => {
      if (!derived) return "";
      const age = Math.floor(i / WEEKS_PER_YEAR);
      const names = (derived.cellPeriods[i] ?? []).map((p) => p.name);
      return names.length ? `Age ${age} · ${names.join(" + ")}` : `Age ${age}`;
    };
  }, [derived]);

  if (isLoading && !birthKey) {
    return (
      <div className="flex h-full items-center justify-center">
        <div className="h-40 w-full max-w-3xl animate-pulse rounded-2xl bg-surface-2" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="grid h-full place-items-center p-6">
        <div className="max-w-sm text-center">
          <h2 className="text-base font-semibold">Life overview unavailable</h2>
          <p className="mt-1 text-sm text-muted">
            We couldn&apos;t load your weeks. Your data is still safe.
          </p>
          <Button
            variant="secondary"
            className="mt-4"
            onClick={() => mutate()}
          >
            <RefreshCw className="h-4 w-4" />
            Try again
          </Button>
        </div>
      </div>
    );
  }

  if (!birthKey || !derived) {
    return <EmptyState onSaved={() => mutate()} />;
  }

  const { stats, cellPeriods, notesByIndex, noteWeeks, milestoneWeeks, total } = derived;
  const maxYear = Math.ceil(total / WEEKS_PER_YEAR) - 1;

  function focusWeek(weekIndex: number, opts?: { flash?: boolean }) {
    setJump((j) => ({ week: weekIndex, token: (j?.token ?? 0) + 1 }));
    if (opts?.flash) wallRef.current?.flashRow(Math.floor(weekIndex / WEEKS_PER_YEAR));
  }

  const activeWeek = jump?.week ?? stats.currentWeek;
  const activeYear = Math.floor(activeWeek / WEEKS_PER_YEAR);
  const focusCol = activeWeek % WEEKS_PER_YEAR;
  const jumpToken = jump?.token ?? 0;

  const selectedNote = openWeek !== null ? notesByIndex.get(openWeek) : undefined;
  const selectedPeriodNames =
    openWeek !== null ? (cellPeriods[openWeek] ?? []).map((p) => p.name) : [];
  const selectedHeadline = openWeek !== null ? labelFor(openWeek).split(" — ")[0] : "";
  const selectedRange =
    openWeek !== null
      ? `${fmtUtc(weekStartUtc(birthKey, openWeek))} – ${fmtUtc(weekEndUtc(birthKey, openWeek))}`
      : "";

  return (
    <div className="flex h-full flex-col">
      <header className="shrink-0 border-b border-border px-4 py-4 md:px-6">
        <div className="flex items-start justify-between gap-4">
          <div className="min-w-0">
            <h1 className="text-lg font-semibold tracking-tight">
              Life in weeks
            </h1>
            <p className="mt-0.5 text-sm text-muted">
              Each row is one year, starting on your birthday.
            </p>
          </div>
          <Button
            variant="secondary"
            size="sm"
            onClick={() => setPeriodsOpen(true)}
            className="shrink-0"
          >
            <Layers className="h-3.5 w-3.5" />
            Periods
          </Button>
        </div>

        <div className="mt-3 flex items-center justify-between gap-4 text-xs text-muted">
          <p>
            <span className="font-semibold text-foreground">
              {stats.years} years, {stats.weeksIntoYear} weeks
            </span>{" "}
            old
          </p>
          <p className="text-right tabular-nums">
            {stats.weeksRemaining.toLocaleString()} weeks ahead in your{" "}
            {years}-year view
          </p>
        </div>
        <div
          className="mt-2 h-1.5 overflow-hidden rounded-full bg-surface-2"
          role="progressbar"
          aria-label="Life view progress"
          aria-valuemin={0}
          aria-valuemax={100}
          aria-valuenow={Math.round(stats.fractionLived * 100)}
        >
          <div
            className="h-full rounded-full bg-primary"
            style={{ width: `${stats.fractionLived * 100}%` }}
          />
        </div>

        <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1.5 text-xs text-muted">
          {life.periods.slice(0, 4).map((period) => (
            <button
              key={period.id}
              type="button"
              onClick={() =>
                focusWeek(weekIndexFor(birthKey, period.startDate), { flash: true })
              }
              className="flex max-w-40 items-center gap-1.5 hover:text-foreground"
            >
              <span
                className="h-2.5 w-2.5 shrink-0 rounded-xs"
                style={{ backgroundColor: period.color }}
              />
              <span className="truncate">{period.name}</span>
            </button>
          ))}
          {life.periods.length > 4 && (
            <button
              type="button"
              onClick={() => setPeriodsOpen(true)}
              className="font-medium text-primary hover:text-primary-hover"
            >
              +{life.periods.length - 4} more
            </button>
          )}
          {life.periods.length === 0 && (
            <button
              type="button"
              onClick={() => setPeriodsOpen(true)}
              className="font-medium text-primary hover:text-primary-hover"
            >
              Mark the chapters of your life →
            </button>
          )}
        </div>
      </header>

      <div className="min-h-0 flex-1 px-2 pt-2">
        <LifeWall
          ref={wallRef}
          totalWeeks={total}
          currentWeek={stats.currentWeek}
          cellPeriods={cellPeriods}
          noteWeeks={noteWeeks}
          milestoneWeeks={milestoneWeeks}
          onFocusWeek={focusWeek}
          labelFor={magnifierLabelFor}
        />
      </div>

      <WeekFilmstrip
        year={activeYear}
        focusCol={focusCol}
        jumpToken={jumpToken}
        totalWeeks={total}
        currentWeek={stats.currentWeek}
        cellPeriods={cellPeriods}
        noteWeeks={noteWeeks}
        milestoneWeeks={milestoneWeeks}
        labelFor={labelFor}
        onOpenWeek={setOpenWeek}
        onPrevYear={() => focusWeek(Math.max(0, activeYear - 1) * WEEKS_PER_YEAR)}
        onNextYear={() => focusWeek(Math.min(maxYear, activeYear + 1) * WEEKS_PER_YEAR)}
        onToday={() => focusWeek(stats.currentWeek, { flash: true })}
        maxYear={maxYear}
      />

      {openWeek !== null && (
        <WeekReviewPanel
          key={openWeek}
          weekIndex={openWeek}
          note={selectedNote}
          headline={selectedHeadline}
          dateRange={selectedRange}
          periodNames={selectedPeriodNames}
          onClose={() => setOpenWeek(null)}
          onSave={saveNote}
        />
      )}

      {periodsOpen && (
        <PeriodsSheet
          open
          onClose={() => setPeriodsOpen(false)}
          periods={life.periods}
          onCreate={createPeriod}
          onUpdate={updatePeriod}
          onDelete={deletePeriod}
        />
      )}
    </div>
  );
}
