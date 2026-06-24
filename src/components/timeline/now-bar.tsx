"use client";

import { Clock, Pause, Play, X } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { CategoryDot, CategoryPicker } from "@/components/timeline/category-picker";
import { useClickOutside } from "@/lib/client/use-click-outside";
import { useSuggestions } from "@/lib/client/use-suggestions";
import { cn } from "@/lib/cn";
import type { CategoryDTO, TimeEntryDTO } from "@/lib/types";

function stopwatch(ms: number): string {
  const total = Math.max(0, Math.floor(ms / 1000));
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
}

function nowHHMM(): string {
  const d = new Date();
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
}

/** Parse a "HH:MM" string into an absolute Date, or null if invalid. */
function parseStartAt(hhMM: string): Date | null {
  const [h, m] = hhMM.split(":").map(Number);
  if (!Number.isFinite(h) || !Number.isFinite(m) || h < 0 || h > 23 || m < 0 || m > 59)
    return null;
  const d = new Date();
  d.setHours(h, m, 0, 0);
  return d;
}

export function NowBar({
  categories,
  runningEntry,
  onStart,
  onStop,
  onCreateCategory,
}: {
  categories: CategoryDTO[];
  runningEntry: TimeEntryDTO | null;
  onStart: (description: string, categoryId: string | null, startTime?: Date) => Promise<void>;
  onStop: () => Promise<void>;
  onCreateCategory: (name: string) => Promise<CategoryDTO>;
}) {
  const [description, setDescription] = useState("");
  const [categoryId, setCategoryId] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [focused, setFocused] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  // "" means "start now"; a "HH:MM" string means a specific past start time.
  const [startAt, setStartAt] = useState("");

  const wrapRef = useRef<HTMLDivElement>(null);
  useClickOutside(wrapRef, () => setFocused(false), focused);

  const { suggestions } = useSuggestions(description);

  // Tick the running timer once a second.
  useEffect(() => {
    if (!runningEntry) return;
    const start = Date.parse(runningEntry.startTime);
    const update = () => setElapsed(Date.now() - start);
    update();
    const id = setInterval(update, 1000);
    return () => clearInterval(id);
  }, [runningEntry]);

  const runningCategory = runningEntry?.categoryId
    ? categories.find((c) => c.id === runningEntry.categoryId)
    : null;

  function toggleStartAt() {
    setStartAt((prev) => (prev ? "" : nowHHMM()));
  }

  async function handleStart() {
    if (busy) return;
    setBusy(true);
    try {
      const customStart = startAt ? (parseStartAt(startAt) ?? undefined) : undefined;
      await onStart(description.trim(), categoryId, customStart);
      setDescription("");
      setCategoryId(null);
      setStartAt("");
      setFocused(false);
    } finally {
      setBusy(false);
    }
  }

  async function handleStop() {
    if (busy) return;
    setBusy(true);
    try {
      await onStop();
    } finally {
      setBusy(false);
    }
  }

  if (runningEntry) {
    const startedAt = new Date(runningEntry.startTime);
    const startedLabel = `${String(startedAt.getHours()).padStart(2, "0")}:${String(startedAt.getMinutes()).padStart(2, "0")}`;
    return (
      <div className="flex items-center gap-3 rounded-2xl border border-border bg-surface px-4 py-3 shadow-sm">
        <span className="h-2 w-2 shrink-0 animate-pulse rounded-full bg-now-line" />
        <div className="min-w-0 flex-1">
          <p className="truncate text-sm font-medium">
            {runningEntry.description || "Untitled"}
          </p>
          <span className="mt-0.5 inline-flex items-center gap-1.5 text-xs text-muted">
            {runningCategory && (
              <>
                <CategoryDot color={runningCategory.color} className="h-2 w-2" />
                <span>{runningCategory.name}</span>
                <span>·</span>
              </>
            )}
            Since {startedLabel}
          </span>
        </div>
        <span className="font-mono text-lg font-semibold tabular-nums">
          {stopwatch(elapsed)}
        </span>
        <button
          type="button"
          onClick={handleStop}
          disabled={busy}
          aria-label="Stop timer"
          className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-now-line text-white transition-transform hover:scale-105 disabled:opacity-50"
        >
          <Pause className="h-5 w-5" />
        </button>
      </div>
    );
  }

  return (
    <div
      ref={wrapRef}
      className="relative rounded-2xl border border-border bg-surface px-3 py-2.5 shadow-sm"
    >
      <div className="flex items-center gap-2">
        <input
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          onFocus={() => setFocused(true)}
          onKeyDown={(e) => {
            if (e.key === "Enter") handleStart();
          }}
          placeholder="What are you working on?"
          className="h-11 min-w-0 flex-1 bg-transparent px-1 text-sm placeholder:text-faint focus:outline-none"
        />
        <button
          type="button"
          onClick={toggleStartAt}
          aria-label={startAt ? "Clear start time" : "Set start time"}
          title={startAt ? "Started at a custom time — click to reset to now" : "Started earlier? Set the start time"}
          className={cn(
            "grid h-8 w-8 shrink-0 place-items-center rounded-lg transition-colors",
            startAt
              ? "bg-primary/10 text-primary"
              : "text-muted hover:bg-surface-2 hover:text-foreground",
          )}
        >
          <Clock className="h-4 w-4" />
        </button>
        <CategoryPicker
          categories={categories}
          value={categoryId}
          onChange={setCategoryId}
          onCreate={onCreateCategory}
          size="sm"
        />
        <button
          type="button"
          onClick={handleStart}
          disabled={busy}
          aria-label="Start timer"
          className="grid h-11 w-11 shrink-0 place-items-center rounded-full bg-primary text-primary-foreground transition-transform hover:scale-105 disabled:opacity-50"
        >
          <Play className="h-5 w-5 translate-x-0.5" />
        </button>
      </div>

      {/* Custom start time row */}
      {startAt && (
        <div className="mt-1.5 flex items-center gap-2 px-1">
          <span className="text-xs text-muted">Started at</span>
          <input
            type="text"
            inputMode="numeric"
            value={startAt}
            onChange={(e) => {
              const raw = e.target.value.replace(/[^\d:]/g, "").slice(0, 5);
              setStartAt(raw);
            }}
            placeholder="HH:MM"
            maxLength={5}
            className="w-16 rounded-md border border-border bg-transparent px-2 py-0.5 text-sm tabular-nums text-foreground focus:outline-none focus:ring-1 focus:ring-primary"
          />
          <button
            type="button"
            onClick={() => setStartAt("")}
            aria-label="Reset to now"
            className="grid h-5 w-5 place-items-center rounded text-muted hover:text-foreground"
          >
            <X className="h-3.5 w-3.5" />
          </button>
        </div>
      )}

      {focused && suggestions.length > 0 && (
        <div className="absolute inset-x-2 top-full z-40 mt-1 overflow-hidden rounded-xl border border-border bg-surface shadow-lg">
          <div className="max-h-64 overflow-y-auto py-1">
            {suggestions.map((s, i) => {
              const cat = s.categoryId
                ? categories.find((c) => c.id === s.categoryId)
                : null;
              return (
                <button
                  key={`${s.description}-${s.categoryId ?? "none"}-${i}`}
                  type="button"
                  onClick={() => {
                    setDescription(s.description);
                    setCategoryId(s.categoryId);
                    setFocused(false);
                  }}
                  className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm hover:bg-surface-2"
                >
                  {cat ? (
                    <CategoryDot color={cat.color} />
                  ) : (
                    <span className="h-2.5 w-2.5" />
                  )}
                  <span className="flex-1 truncate">{s.description}</span>
                  {cat && (
                    <span className="shrink-0 text-xs text-faint">{cat.name}</span>
                  )}
                </button>
              );
            })}
          </div>
        </div>
      )}
    </div>
  );
}
