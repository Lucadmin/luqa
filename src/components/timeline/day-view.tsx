"use client";

import { ChevronLeft, ChevronRight, Moon } from "lucide-react";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { EntryEditor, type SaveResult } from "@/components/timeline/entry-editor";
import { HabitsStrip } from "@/components/timeline/habits-strip";
import { NowBar } from "@/components/timeline/now-bar";
import { SleepEditor } from "@/components/timeline/sleep-editor";
import { Timeline, type TimelineHandle } from "@/components/timeline/timeline";
import type { EntryDraft, InlineDraft } from "@/components/timeline/types";
import {
  createCategory,
  useCategories,
} from "@/lib/client/use-categories";
import { useDebounced } from "@/lib/client/use-debounced";
import { useEntriesRange } from "@/lib/client/use-entries";
import { useSettings } from "@/lib/client/use-settings";
import { useSleepRange } from "@/lib/client/use-sleep-entries";
import {
  addDays,
  dayNumber,
  formatDuration,
  isoDateKey,
  logicalDayKey,
  MINUTES_PER_DAY,
  minutesToDate,
  startOfLocalDay,
  startOfViewDay,
} from "@/lib/time";
import type { SleepEntryDTO, TimeEntryDTO } from "@/lib/types";

/** The logical "today" respects the day-start cutoff: before it we're still yesterday. */
function logicalToday(startHour?: number): Date {
  return startOfViewDay(new Date(), startHour);
}

function dayLabel(day: Date, startHour: number): string {
  const today = logicalToday(startHour);
  const key = isoDateKey(day);
  if (key === isoDateKey(today)) return "Today";
  if (key === isoDateKey(addDays(today, -1))) return "Yesterday";
  if (key === isoDateKey(addDays(today, 1))) return "Tomorrow";
  return day.toLocaleDateString(undefined, {
    weekday: "long",
    month: "short",
    day: "numeric",
  });
}

function sleepMinutes(entry: { sleepMinutes: number | null; awakeMinutes: number | null; startTime: string; endTime: string }) {
  if (entry.sleepMinutes !== null) return entry.sleepMinutes;
  const duration = (Date.parse(entry.endTime) - Date.parse(entry.startTime)) / 60000;
  return Math.max(0, duration - (entry.awakeMinutes ?? 0));
}

export function DayView() {
  const { settings } = useSettings();
  const dayStartHour = settings.dayStartHour;

  const timelineRef = useRef<TimelineHandle>(null);

  // The day at the top of the timeline. The timeline reports it while
  // scrolling; the header controls scroll it back the other way.
  const [day, setDay] = useState(() => logicalToday());
  const [draft, setDraft] = useState<EntryDraft | null>(null);
  const [inlineDraft, setInlineDraft] = useState<InlineDraft | null>(null);
  const [selectedSleep, setSelectedSleep] = useState<SleepEntryDTO | null>(null);
  const [saving, setSaving] = useState(false);

  // Keep the identity stable while the same day stays on top, so everything
  // downstream (fetch windows, habit strip) only reacts to real day changes.
  const handleDayChange = useCallback((next: Date) => {
    setDay((prev) => (isoDateKey(prev) === isoDateKey(next) ? prev : next));
  }, []);

  // A single ticking clock; everything time-dependent derives from it so
  // render stays pure (no Date.now()/new Date() during render).
  const [nowTick, setNowTick] = useState(() => Date.now());
  useEffect(() => {
    const id = setInterval(() => setNowTick(Date.now()), 30_000);
    return () => clearInterval(id);
  }, []);

  const isToday = isoDateKey(day) === logicalDayKey(new Date(nowTick), dayStartHour);

  // Data is fetched in three-week windows quantised to whole weeks, so the key
  // only changes every seventh day of scrolling and always keeps a week of
  // slack on either side of what's on screen.
  const windowFrom = useMemo(() => {
    const weekday = ((dayNumber(day) % 7) + 7) % 7;
    return addDays(startOfLocalDay(day), -weekday - 7);
  }, [day]);
  const windowTo = useMemo(() => addDays(windowFrom, 21), [windowFrom]);

  const { entries, createEntry, updateEntry, deleteEntry } = useEntriesRange(
    windowFrom,
    windowTo,
  );
  const { sleepEntries, updateSleepEntry } = useSleepRange(windowFrom, windowTo);
  const { categories, mutate: mutateCategories } = useCategories();

  // Habits refetch per day; let fast scrolling settle before asking.
  const habitsDay = useDebounced(day, 250);

  const runningEntry = useMemo(
    () => entries.find((e) => e.endTime === null) ?? null,
    [entries],
  );

  const categoryById = useMemo(
    () => new Map(categories.map((c) => [c.id, c])),
    [categories],
  );

  // Completed entries on the draft's day as colored bands for the editor dial
  // (context: where the day is already filled). The editor excludes the active one.
  const draftDayMs = draft ? startOfLocalDay(draft.day).getTime() : null;
  const daySegments = useMemo(() => {
    if (draftDayMs === null) return [];
    return entries.flatMap((e) => {
      if (!e.endTime) return [];
      const startMin = (Date.parse(e.startTime) - draftDayMs) / 60000;
      const endMin = (Date.parse(e.endTime) - draftDayMs) / 60000;
      if (endMin <= 0 || startMin >= MINUTES_PER_DAY) return [];
      const color = e.categoryId
        ? (categoryById.get(e.categoryId)?.color ?? "#9aa0aa")
        : "#9aa0aa";
      return [
        {
          id: e.id,
          startMin: Math.max(0, startMin),
          endMin: Math.min(MINUTES_PER_DAY, endMin),
          color,
        },
      ];
    });
  }, [entries, categoryById, draftDayMs]);

  const dayTotal = useMemo(() => {
    const displayedKey = isoDateKey(day);
    let total = 0;
    for (const e of entries) {
      // Only count entries whose logical day matches the displayed day, so
      // cross-midnight entries aren't double-counted on both adjacent days.
      if (logicalDayKey(new Date(e.startTime), dayStartHour) !== displayedKey) continue;
      const start = Date.parse(e.startTime);
      const end = e.endTime ? Date.parse(e.endTime) : nowTick;
      total += Math.max(0, (end - start) / 60000);
    }
    return total;
  }, [entries, nowTick, day, dayStartHour]);

  // Sleep is attributed to the logical day it woke up in.
  const sleepTotal = useMemo(() => {
    const displayedKey = isoDateKey(day);
    return sleepEntries.reduce(
      (total, entry) =>
        logicalDayKey(new Date(entry.endTime), dayStartHour) === displayedKey
          ? total + sleepMinutes(entry)
          : total,
      0,
    );
  }, [sleepEntries, day, dayStartHour]);

  async function handleCreateCategory(name: string) {
    const cat = await createCategory(name);
    await mutateCategories();
    return cat;
  }

  async function handleStart(
    description: string,
    categoryId: string | null,
    startTime?: Date,
  ) {
    await createEntry({
      description,
      categoryId,
      startTime: (startTime ?? new Date()).toISOString(),
      endTime: null,
    });
  }

  async function handleStop() {
    if (!runningEntry) return;
    await updateEntry(runningEntry.id, { endTime: new Date().toISOString() });
  }

  function openEntry(entry: TimeEntryDTO) {
    if (entry.endTime === null) return; // running entry is managed by the timer
    setInlineDraft(null);
    // Anchor on the day the entry *starts*, so editing the tail of a
    // cross-midnight entry can't silently truncate its front half.
    const refDay = startOfLocalDay(new Date(entry.startTime));
    const base = refDay.getTime();
    setDraft({
      id: entry.id,
      day: refDay,
      description: entry.description,
      categoryId: entry.categoryId,
      startMin: Math.round((Date.parse(entry.startTime) - base) / 60000),
      endMin: Math.round((Date.parse(entry.endTime) - base) / 60000),
    });
  }

  function openSleep(entry: SleepEntryDTO) {
    setDraft(null);
    setInlineDraft(null);
    setSelectedSleep(entry);
  }

  // ── In-place draft block (drag/tap-to-create) ──────────────────────────────
  function createInline(day: Date, startMin: number, endMin: number, autoFocus: boolean) {
    setDraft(null);
    setInlineDraft({ day, description: "", categoryId: null, startMin, endMin, autoFocus });
  }

  function changeInlineRange(startMin: number, endMin: number) {
    setInlineDraft((d) => (d ? { ...d, startMin, endMin } : d));
  }

  function changeInlineDescription(description: string) {
    setInlineDraft((d) => (d ? { ...d, description } : d));
  }

  // Picking a suggestion fills both the title and its remembered category.
  function applyInlineSuggestion(description: string, categoryId: string | null) {
    setInlineDraft((d) => (d ? { ...d, description, categoryId } : d));
  }

  async function saveInline() {
    if (!inlineDraft) return;
    setSaving(true);
    try {
      await createEntry({
        description: inlineDraft.description,
        categoryId: inlineDraft.categoryId,
        startTime: minutesToDate(inlineDraft.day, inlineDraft.startMin).toISOString(),
        endTime: minutesToDate(inlineDraft.day, inlineDraft.endMin).toISOString(),
      });
      setInlineDraft(null);
    } finally {
      setSaving(false);
    }
  }

  // Hand the inline draft off to the full editor popup for richer controls.
  function expandInline() {
    if (!inlineDraft) return;
    setDraft({
      day: inlineDraft.day,
      description: inlineDraft.description,
      categoryId: inlineDraft.categoryId,
      startMin: inlineDraft.startMin,
      endMin: inlineDraft.endMin,
    });
    setInlineDraft(null);
  }

  async function handleSave(result: SaveResult) {
    if (!draft) return;
    setSaving(true);
    try {
      const payload = {
        description: result.description,
        categoryId: result.categoryId,
        startTime: minutesToDate(draft.day, result.startMin).toISOString(),
        endTime: minutesToDate(draft.day, result.endMin).toISOString(),
      };
      if (draft.id) {
        await updateEntry(draft.id, payload);
      } else {
        await createEntry(payload);
      }

      // Chain gap-filling: the freed space below becomes the next entry.
      if (result.nextGap) {
        setDraft({
          day: draft.day,
          description: "",
          categoryId: null,
          startMin: result.nextGap.startMin,
          endMin: result.nextGap.endMin,
          gapEndMin: result.nextGap.endMin,
        });
      } else {
        setDraft(null);
      }
    } finally {
      setSaving(false);
    }
  }

  async function handleDelete() {
    if (!draft?.id) return;
    setSaving(true);
    try {
      await deleteEntry(draft.id);
      setDraft(null);
    } finally {
      setSaving(false);
    }
  }

  function jumpToDate(value: string) {
    const [y, m, d] = value.split("-").map(Number);
    if (!y || !m || !d) return;
    timelineRef.current?.goToDay(new Date(y, m - 1, d));
  }

  return (
    <div className="flex h-full flex-col">
      {/* header + timer */}
      <div className="z-20 shrink-0 border-b border-border bg-background px-4 pb-3 pt-4 md:px-8 md:pt-6">
        <div className="mx-auto flex w-full max-w-3xl items-center justify-between">
          <div className="flex items-center gap-1">
            <button
              type="button"
              aria-label="Previous day"
              onClick={() => timelineRef.current?.shiftDays(-1)}
              className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>

            {/* the label doubles as a date picker — picking scrolls there */}
            <div className="relative">
              <h1 className="min-w-28 text-center text-base font-semibold">
                {dayLabel(day, dayStartHour)}
              </h1>
              <input
                type="date"
                aria-label="Jump to date"
                value={isoDateKey(day)}
                onClick={(e) => {
                  try {
                    e.currentTarget.showPicker();
                  } catch {
                    /* not supported — the native control handles it */
                  }
                }}
                onChange={(e) => jumpToDate(e.target.value)}
                className="absolute inset-0 h-full w-full cursor-pointer opacity-0"
              />
            </div>

            <button
              type="button"
              aria-label="Next day"
              onClick={() => timelineRef.current?.shiftDays(1)}
              className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
            {!isToday && (
              <button
                type="button"
                onClick={() => timelineRef.current?.goToNow()}
                className="ml-2 rounded-full border border-border px-2.5 py-1 text-xs font-medium text-muted hover:bg-surface-2"
              >
                Today
              </button>
            )}
          </div>
          <span className="flex items-center gap-3 text-sm text-muted">
            <span>
              <span className="font-semibold text-foreground tabular-nums">
                {formatDuration(dayTotal)}
              </span>{" "}
              tracked
            </span>
            {sleepTotal > 0 && (
              <span className="inline-flex items-center gap-1.5">
                <Moon className="h-3.5 w-3.5 text-faint" />
                <span className="font-semibold text-foreground tabular-nums">
                  {formatDuration(sleepTotal)}
                </span>{" "}
                sleep
              </span>
            )}
          </span>
        </div>

        <div className="mx-auto mt-3 w-full max-w-3xl">
          <NowBar
            categories={categories}
            runningEntry={runningEntry}
            onStart={handleStart}
            onStop={handleStop}
            onCreateCategory={handleCreateCategory}
          />
        </div>

        <div className="mx-auto mt-3 w-full max-w-3xl">
          <HabitsStrip day={habitsDay} />
        </div>
      </div>

      {/* the timeline owns its own scroller — it runs forever in both directions */}
      <Timeline
        ref={timelineRef}
        dayStartHour={dayStartHour}
        nowMs={nowTick}
        entries={entries}
        sleepEntries={sleepEntries}
        categories={categories}
        inlineDraft={inlineDraft}
        onDayChange={handleDayChange}
        onOpenEntry={openEntry}
        onOpenSleep={openSleep}
        onCreateInline={createInline}
        onChangeInlineRange={changeInlineRange}
        onChangeInlineDescription={changeInlineDescription}
        onApplyInlineSuggestion={applyInlineSuggestion}
        onSaveInline={saveInline}
        onExpandInline={expandInline}
        onCancelInline={() => setInlineDraft(null)}
        saving={saving}
      />

      {draft && (
        <EntryEditor
          key={draft.id ?? `${isoDateKey(draft.day)}-${draft.startMin}-${draft.endMin}`}
          draft={draft}
          categories={categories}
          segments={daySegments.filter((s) => s.id !== draft.id)}
          maxEndMin={Math.max(
            MINUTES_PER_DAY + Math.max(1, dayStartHour) * 60,
            draft.endMin,
          )}
          onSave={handleSave}
          onDelete={draft.id ? handleDelete : undefined}
          onClose={() => setDraft(null)}
          onCreateCategory={handleCreateCategory}
          saving={saving}
        />
      )}

      <SleepEditor
        entry={selectedSleep}
        onClose={() => setSelectedSleep(null)}
        onSave={async (id, patch) => {
          const updated = await updateSleepEntry(id, patch);
          setSelectedSleep(updated);
          return updated;
        }}
      />
    </div>
  );
}
