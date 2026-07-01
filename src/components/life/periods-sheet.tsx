"use client";

import { Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import type { PeriodInput } from "@/lib/client/use-life";
import { cn } from "@/lib/cn";
import { PERIOD_PALETTE } from "@/lib/life";
import type { LifePeriodDTO } from "@/lib/types";

interface PeriodsSheetProps {
  open: boolean;
  onClose: () => void;
  periods: LifePeriodDTO[];
  onCreate: (input: PeriodInput) => Promise<unknown>;
  onUpdate: (id: string, input: Partial<PeriodInput>) => Promise<unknown>;
  onDelete: (id: string) => Promise<unknown>;
}

function formatRange(p: LifePeriodDTO): string {
  const fmt = (k: string) =>
    new Date(`${k}T00:00:00.000Z`).toLocaleDateString(undefined, {
      year: "numeric",
      month: "short",
      timeZone: "UTC",
    });
  return `${fmt(p.startDate)} – ${p.endDate ? fmt(p.endDate) : "now"}`;
}

interface FormState {
  name: string;
  color: string;
  startDate: string;
  endDate: string;
  ongoing: boolean;
}

function emptyForm(): FormState {
  return {
    name: "",
    color: PERIOD_PALETTE[0],
    startDate: "",
    endDate: "",
    ongoing: true,
  };
}

function PeriodForm({
  initial,
  submitLabel,
  onSubmit,
  onCancel,
}: {
  initial: FormState;
  submitLabel: string;
  onSubmit: (input: PeriodInput) => Promise<unknown>;
  onCancel: () => void;
}) {
  const [form, setForm] = useState<FormState>(initial);
  const [busy, setBusy] = useState(false);

  const valid =
    form.name.trim().length > 0 &&
    form.startDate.length > 0 &&
    (form.ongoing || (form.endDate.length > 0 && form.endDate >= form.startDate));

  async function submit() {
    if (!valid) return;
    setBusy(true);
    try {
      await onSubmit({
        name: form.name.trim(),
        color: form.color,
        startDate: form.startDate,
        endDate: form.ongoing ? null : form.endDate,
      });
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col gap-3 rounded-xl border border-border bg-surface-2/50 p-3">
      <Input
        value={form.name}
        onChange={(e) => setForm({ ...form, name: e.target.value })}
        placeholder="Name (e.g. University, Relationship with …)"
        className="h-10"
      />

      <div className="flex flex-wrap gap-1.5">
        {PERIOD_PALETTE.map((c) => (
          <button
            key={c}
            type="button"
            aria-label={`Colour ${c}`}
            onClick={() => setForm({ ...form, color: c })}
            style={{ backgroundColor: c }}
            className={cn(
              "h-6 w-6 rounded-full transition-transform",
              form.color === c
                ? "ring-2 ring-foreground ring-offset-2 ring-offset-surface"
                : "hover:scale-110",
            )}
          />
        ))}
      </div>

      <div className="flex flex-wrap items-center gap-3">
        <label className="flex flex-col gap-1 text-xs text-muted">
          Start
          <input
            type="date"
            value={form.startDate}
            max={new Date().toISOString().slice(0, 10)}
            onChange={(e) => setForm({ ...form, startDate: e.target.value })}
            className="h-9 rounded-lg border border-border bg-surface px-2 text-sm tabular-nums focus:outline-none focus-visible:border-primary"
          />
        </label>
        <label className="flex flex-col gap-1 text-xs text-muted">
          End
          <input
            type="date"
            value={form.endDate}
            min={form.startDate || undefined}
            disabled={form.ongoing}
            onChange={(e) => setForm({ ...form, endDate: e.target.value })}
            className="h-9 rounded-lg border border-border bg-surface px-2 text-sm tabular-nums focus:outline-none focus-visible:border-primary disabled:opacity-40"
          />
        </label>
        <label className="flex items-center gap-1.5 self-end pb-1 text-xs text-muted">
          <input
            type="checkbox"
            checked={form.ongoing}
            onChange={(e) => setForm({ ...form, ongoing: e.target.checked })}
            className="h-4 w-4 accent-primary"
          />
          Ongoing
        </label>
      </div>

      <div className="flex items-center justify-end gap-2">
        <Button variant="secondary" size="sm" onClick={onCancel} disabled={busy}>
          Cancel
        </Button>
        <Button size="sm" onClick={submit} disabled={!valid || busy}>
          {busy ? "Saving…" : submitLabel}
        </Button>
      </div>
    </div>
  );
}

export function PeriodsSheet({
  open,
  onClose,
  periods,
  onCreate,
  onUpdate,
  onDelete,
}: PeriodsSheetProps) {
  const [adding, setAdding] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);

  return (
    <Sheet open={open} onClose={onClose} title="Life periods">
      <div className="flex flex-col gap-3">
        {periods.length === 0 && !adding && (
          <p className="text-sm text-muted">
            Mark the chapters of your life — university, a relationship, a job.
            They can overlap and appear as coloured bands on the grid.
          </p>
        )}

        {periods.map((p) =>
          editingId === p.id ? (
            <PeriodForm
              key={p.id}
              submitLabel="Save"
              initial={{
                name: p.name,
                color: p.color,
                startDate: p.startDate,
                endDate: p.endDate ?? "",
                ongoing: p.endDate === null,
              }}
              onSubmit={async (input) => {
                await onUpdate(p.id, input);
                setEditingId(null);
              }}
              onCancel={() => setEditingId(null)}
            />
          ) : (
            <div
              key={p.id}
              className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5"
            >
              <span
                className="h-4 w-4 shrink-0 rounded-full"
                style={{ backgroundColor: p.color }}
              />
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm font-medium">{p.name}</p>
                <p className="text-xs text-faint">{formatRange(p)}</p>
              </div>
              <button
                type="button"
                aria-label="Edit period"
                onClick={() => {
                  setAdding(false);
                  setEditingId(p.id);
                }}
                className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-foreground"
              >
                <Pencil className="h-3.5 w-3.5" />
              </button>
              <button
                type="button"
                aria-label="Delete period"
                onClick={() => onDelete(p.id)}
                className="grid h-8 w-8 place-items-center rounded-lg text-muted hover:bg-surface-2 hover:text-red-500"
              >
                <Trash2 className="h-3.5 w-3.5" />
              </button>
            </div>
          ),
        )}

        {adding ? (
          <PeriodForm
            submitLabel="Add"
            initial={emptyForm()}
            onSubmit={async (input) => {
              await onCreate(input);
              setAdding(false);
            }}
            onCancel={() => setAdding(false)}
          />
        ) : (
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              setEditingId(null);
              setAdding(true);
            }}
            className="self-start"
          >
            <Plus className="h-3.5 w-3.5" /> Add period
          </Button>
        )}
      </div>
    </Sheet>
  );
}
