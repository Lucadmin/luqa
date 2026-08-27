"use client";

import { Moon, Pencil } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import type { SleepEntryPatch } from "@/lib/client/use-sleep-entries";
import { formatDuration } from "@/lib/time";
import type { SleepEntryDTO } from "@/lib/types";

const STAGE_COLORS: Record<string, string> = {
  deep: "#6366f1",
  rem: "#ec4899",
  light: "#38bdf8",
  awake: "#f59e0b",
  sleep: "#8b9aaa",
};

function minutesBetween(startISO: string, endISO: string): number {
  return Math.max(0, Math.round((Date.parse(endISO) - Date.parse(startISO)) / 60000));
}

function toLocalInputValue(iso: string): string {
  const d = new Date(iso);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  const h = String(d.getHours()).padStart(2, "0");
  const min = String(d.getMinutes()).padStart(2, "0");
  return `${y}-${m}-${day}T${h}:${min}`;
}

function fromLocalInputValue(value: string): string {
  return new Date(value).toISOString();
}

function clockRange(startISO: string, endISO: string): string {
  const opts: Intl.DateTimeFormatOptions = { hour: "2-digit", minute: "2-digit", hour12: false };
  return `${new Date(startISO).toLocaleTimeString(undefined, opts)}-${new Date(endISO).toLocaleTimeString(undefined, opts)}`;
}

function sleepMinutes(entry: SleepEntryDTO): number {
  if (entry.sleepMinutes !== null) return entry.sleepMinutes;
  return Math.max(0, minutesBetween(entry.startTime, entry.endTime) - (entry.awakeMinutes ?? 0));
}

function sourceLabel(entry: SleepEntryDTO): string {
  if (entry.sourceApp) return entry.sourceApp;
  if (entry.source === "GOOGLE_HEALTH") return "Google Health";
  if (entry.source === "HEALTH_CONNECT") return "Health Connect";
  return "Manual";
}

export function SleepEditor({
  entry,
  onClose,
  onSave,
}: {
  entry: SleepEntryDTO | null;
  onClose: () => void;
  onSave: (id: string, patch: SleepEntryPatch) => Promise<SleepEntryDTO>;
}) {
  const [startValue, setStartValue] = useState(entry ? toLocalInputValue(entry.startTime) : "");
  const [endValue, setEndValue] = useState(entry ? toLocalInputValue(entry.endTime) : "");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!entry) {
    return null;
  }

  const currentEntry = entry;
  const entryId = currentEntry.id;
  const startISO = startValue ? fromLocalInputValue(startValue) : currentEntry.startTime;
  const endISO = endValue ? fromLocalInputValue(endValue) : currentEntry.endTime;
  const inBed = minutesBetween(startISO, endISO);
  const edited =
    startISO !== currentEntry.startTime || endISO !== currentEntry.endTime;
  const originalInBed = minutesBetween(currentEntry.startTime, currentEntry.endTime);
  const originalAsleep = sleepMinutes(currentEntry);
  const awake = Math.max(0, currentEntry.awakeMinutes ?? originalInBed - originalAsleep);
  const asleep = edited ? Math.max(0, inBed - awake) : Math.min(inBed, originalAsleep);
  const deep = currentEntry.deepMinutes ?? 0;
  const rem = currentEntry.remMinutes ?? 0;
  const light = currentEntry.lightMinutes ?? 0;
  const knownAsleepStages = deep + rem + light;
  const unknownSleep = Math.max(0, asleep - knownAsleepStages);
  const efficiency = inBed > 0 ? Math.round((asleep / inBed) * 100) : 0;
  const stageSegments = [
    { key: "deep", label: "Deep", minutes: deep },
    { key: "rem", label: "REM", minutes: rem },
    { key: "light", label: "Light", minutes: light },
    { key: "awake", label: "Awake", minutes: awake },
    { key: "sleep", label: "Other", minutes: unknownSleep },
  ].filter((stage) => stage.minutes > 0);

  async function save() {
    setError(null);
    if (Date.parse(endISO) <= Date.parse(startISO)) {
      setError("End must be after start.");
      return;
    }

    setSaving(true);
    try {
      await onSave(entryId, {
        startTime: startISO,
        endTime: endISO,
      });
      onClose();
    } catch {
      setError("Could not save sleep changes.");
    } finally {
      setSaving(false);
    }
  }

  return (
    <Sheet
      open
      onClose={onClose}
      title={
        <span className="inline-flex items-center gap-2">
          <Moon className="h-4 w-4 text-indigo-500" />
          Sleep
        </span>
      }
      footer={
        <div className="flex items-center justify-between gap-3">
          <div className="min-w-0 text-xs text-faint">
            {currentEntry.manualOverrideAt ? "Manually edited" : sourceLabel(currentEntry)}
          </div>
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="sm" onClick={onClose}>
              Cancel
            </Button>
            <Button size="sm" onClick={save} disabled={!edited || saving}>
              <Pencil className="h-3.5 w-3.5" />
              {saving ? "Saving..." : "Save"}
            </Button>
          </div>
        </div>
      }
    >
      <div className="flex flex-col gap-5">
        <div>
          <div className="text-3xl font-bold tabular-nums">{formatDuration(asleep)}</div>
          <div className="mt-1 text-sm text-muted">
            {clockRange(startISO, endISO)} · {sourceLabel(currentEntry)}
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <label className="flex flex-col gap-1.5">
            <span className="text-xs font-medium text-muted">Start</span>
            <Input
              type="datetime-local"
              value={startValue}
              onChange={(e) => setStartValue(e.target.value)}
              className="h-10"
            />
          </label>
          <label className="flex flex-col gap-1.5">
            <span className="text-xs font-medium text-muted">End</span>
            <Input
              type="datetime-local"
              value={endValue}
              onChange={(e) => setEndValue(e.target.value)}
              className="h-10"
            />
          </label>
        </div>

        {error && (
          <p className="rounded-xl border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-400">
            {error}
          </p>
        )}

        <div className="grid grid-cols-4 gap-2">
          <Metric label="In bed" value={formatDuration(inBed)} />
          <Metric label="Asleep" value={formatDuration(asleep)} />
          <Metric label="Awake" value={formatDuration(awake)} />
          <Metric label="Efficiency" value={`${efficiency}%`} />
        </div>

        <div className="rounded-2xl border border-border bg-surface-2/40 p-4">
          <div className="mb-3 flex items-center justify-between">
            <h3 className="text-sm font-semibold">Stages</h3>
            <span className="text-xs text-faint">{entry.stages.length} segments</span>
          </div>
          <div className="flex h-3 overflow-hidden rounded-full bg-surface">
            {stageSegments.length > 0 ? (
              stageSegments.map((stage) => (
                <span
                  key={stage.key}
                  className="h-full"
                  style={{
                    width: `${(stage.minutes / Math.max(1, inBed)) * 100}%`,
                    backgroundColor: STAGE_COLORS[stage.key],
                  }}
                />
              ))
            ) : (
              <span className="h-full w-full bg-muted" />
            )}
          </div>
          <div className="mt-4 grid grid-cols-2 gap-2">
            {stageSegments.map((stage) => (
              <div key={stage.key} className="flex items-center justify-between gap-2">
                <span className="inline-flex items-center gap-1.5 text-xs text-muted">
                  <span
                    className="h-2 w-2 rounded-full"
                    style={{ backgroundColor: STAGE_COLORS[stage.key] }}
                  />
                  {stage.label}
                </span>
                <span className="text-xs tabular-nums text-faint">
                  {formatDuration(stage.minutes)}
                </span>
              </div>
            ))}
          </div>
        </div>

        {entry.manualOverrideAt && (
          <p className="text-xs text-faint">
            Edited {new Date(entry.manualOverrideAt).toLocaleString(undefined, {
              month: "short",
              day: "numeric",
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
            })}
          </p>
        )}
      </div>
    </Sheet>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-xl border border-border bg-surface p-3">
      <p className="text-[11px] text-faint">{label}</p>
      <p className="mt-1 text-sm font-bold tabular-nums">{value}</p>
    </div>
  );
}
