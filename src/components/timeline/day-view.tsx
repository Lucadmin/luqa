"use client";

import { ChevronLeft, ChevronRight } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { EntryEditor, type SaveResult } from "@/components/timeline/entry-editor";
import { NowBar } from "@/components/timeline/now-bar";
import { Timeline } from "@/components/timeline/timeline";
import type { EntryDraft, InlineDraft } from "@/components/timeline/types";
import {
  createCategory,
  useCategories,
} from "@/lib/client/use-categories";
import { useEntries } from "@/lib/client/use-entries";
import {
  formatDuration,
  isoDateKey,
  minutesSinceMidnight,
  minutesToDate,
  startOfLocalDay,
} from "@/lib/time";
import type { TimeEntryDTO } from "@/lib/types";

function addDays(d: Date, n: number) {
  const c = new Date(d);
  c.setDate(c.getDate() + n);
  return c;
}

function dayLabel(day: Date): string {
  const today = isoDateKey(new Date());
  const key = isoDateKey(day);
  if (key === today) return "Today";
  if (key === isoDateKey(addDays(new Date(), -1))) return "Yesterday";
  return day.toLocaleDateString(undefined, {
    weekday: "long",
    month: "short",
    day: "numeric",
  });
}

export function DayView() {
  const [day, setDay] = useState(() => startOfLocalDay(new Date()));
  const [draft, setDraft] = useState<EntryDraft | null>(null);
  const [inlineDraft, setInlineDraft] = useState<InlineDraft | null>(null);
  const [saving, setSaving] = useState(false);

  // A single ticking clock; everything time-dependent derives from it so
  // render stays pure (no Date.now()/new Date() during render).
  const [nowTick, setNowTick] = useState(() => Date.now());
  useEffect(() => {
    const id = setInterval(() => setNowTick(Date.now()), 30_000);
    return () => clearInterval(id);
  }, []);

  const isToday = isoDateKey(day) === isoDateKey(new Date(nowTick));
  const nowMin = isToday ? minutesSinceMidnight(new Date(nowTick)) : null;

  const { entries, createEntry, updateEntry, deleteEntry } = useEntries(day);
  const { categories, mutate: mutateCategories } = useCategories();

  const runningEntry = useMemo(
    () => entries.find((e) => e.endTime === null) ?? null,
    [entries],
  );

  const dayTotal = useMemo(() => {
    let total = 0;
    for (const e of entries) {
      const start = Date.parse(e.startTime);
      const end = e.endTime ? Date.parse(e.endTime) : nowTick;
      total += Math.max(0, (end - start) / 60000);
    }
    return total;
  }, [entries, nowTick]);

  async function handleCreateCategory(name: string) {
    const cat = await createCategory(name);
    await mutateCategories();
    return cat;
  }

  async function handleStart(description: string, categoryId: string | null) {
    await createEntry({
      description,
      categoryId,
      startTime: new Date().toISOString(),
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
    const dayStartMs = startOfLocalDay(day).getTime();
    const startMin = Math.round((Date.parse(entry.startTime) - dayStartMs) / 60000);
    const endMin = Math.round((Date.parse(entry.endTime) - dayStartMs) / 60000);
    setDraft({
      id: entry.id,
      description: entry.description,
      categoryId: entry.categoryId,
      startMin: Math.max(0, startMin),
      endMin: Math.min(24 * 60, endMin),
    });
  }

  // ── In-place draft block (drag/tap-to-create) ──────────────────────────────
  function createInline(startMin: number, endMin: number, autoFocus: boolean) {
    setDraft(null);
    setInlineDraft({ description: "", categoryId: null, startMin, endMin, autoFocus });
  }

  function changeInlineRange(startMin: number, endMin: number) {
    setInlineDraft((d) => (d ? { ...d, startMin, endMin } : d));
  }

  function changeInlineDescription(description: string) {
    setInlineDraft((d) => (d ? { ...d, description } : d));
  }

  async function saveInline() {
    if (!inlineDraft) return;
    setSaving(true);
    try {
      await createEntry({
        description: inlineDraft.description,
        categoryId: inlineDraft.categoryId,
        startTime: minutesToDate(day, inlineDraft.startMin).toISOString(),
        endTime: minutesToDate(day, inlineDraft.endMin).toISOString(),
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
      description: inlineDraft.description,
      categoryId: inlineDraft.categoryId,
      startMin: inlineDraft.startMin,
      endMin: inlineDraft.endMin,
    });
    setInlineDraft(null);
  }

  async function handleSave(result: SaveResult) {
    setSaving(true);
    try {
      const payload = {
        description: result.description,
        categoryId: result.categoryId,
        startTime: minutesToDate(day, result.startMin).toISOString(),
        endTime: minutesToDate(day, result.endMin).toISOString(),
      };
      if (draft?.id) {
        await updateEntry(draft.id, payload);
      } else {
        await createEntry(payload);
      }

      // Chain gap-filling: the freed space below becomes the next entry.
      if (result.nextGap) {
        setDraft({
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

  return (
    <div className="pb-24 md:pb-10">
      {/* sticky header + timer */}
      <div className="sticky top-0 z-20 border-b border-border bg-background/90 px-4 pb-3 pt-4 backdrop-blur md:px-8 md:pt-6">
        <div className="mx-auto flex w-full max-w-3xl items-center justify-between">
          <div className="flex items-center gap-1">
            <button
              type="button"
              aria-label="Previous day"
              onClick={() => setDay((d) => addDays(d, -1))}
              className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
            >
              <ChevronLeft className="h-4 w-4" />
            </button>
            <h1 className="min-w-[7rem] text-center text-base font-semibold">
              {dayLabel(day)}
            </h1>
            <button
              type="button"
              aria-label="Next day"
              onClick={() => setDay((d) => addDays(d, 1))}
              className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
            >
              <ChevronRight className="h-4 w-4" />
            </button>
            {!isToday && (
              <button
                type="button"
                onClick={() => setDay(startOfLocalDay(new Date()))}
                className="ml-2 rounded-full border border-border px-2.5 py-1 text-xs font-medium text-muted hover:bg-surface-2"
              >
                Today
              </button>
            )}
          </div>
          <span className="text-sm text-muted">
            <span className="font-semibold text-foreground tabular-nums">
              {formatDuration(dayTotal)}
            </span>{" "}
            tracked
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
      </div>

      {/* timeline */}
      <div className="mx-auto w-full max-w-3xl px-4 pt-4 md:px-8">
        <Timeline
          day={day}
          entries={entries}
          categories={categories}
          nowMin={nowMin}
          inlineDraft={inlineDraft}
          onOpenEntry={openEntry}
          onCreateInline={createInline}
          onChangeInlineRange={changeInlineRange}
          onChangeInlineDescription={changeInlineDescription}
          onSaveInline={saveInline}
          onExpandInline={expandInline}
          onCancelInline={() => setInlineDraft(null)}
          saving={saving}
        />
      </div>

      {draft && (
        <EntryEditor
          key={draft.id ?? `${draft.startMin}-${draft.endMin}`}
          draft={draft}
          categories={categories}
          onSave={handleSave}
          onDelete={draft.id ? handleDelete : undefined}
          onClose={() => setDraft(null)}
          onCreateCategory={handleCreateCategory}
          saving={saving}
        />
      )}
    </div>
  );
}
