"use client";

import { Trash2 } from "lucide-react";
import { useState } from "react";
import { archiveHabit, createHabit, updateHabit } from "@/lib/client/use-habits";
import { useCategories } from "@/lib/client/use-categories";
import { cn } from "@/lib/cn";
import { DEFAULT_HABIT_ICON, HABIT_COLORS } from "@/lib/habit-icons";
import type { HabitDTO, HabitGoalType } from "@/lib/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import { useSettings } from "@/lib/client/use-settings";
import { IconPicker } from "./icon-picker";
import { type ScheduleValue, SchedulePicker } from "./schedule-picker";
import { Stepper } from "./stepper";

interface Draft {
  name: string;
  icon: string;
  color: string;
  goalType: HabitGoalType;
  targetCount: number;
  targetSeconds: number;
  categoryId: string | null;
  scheduleType: ScheduleValue["scheduleType"];
  weekdays: number[];
  weekInterval: number;
  intervalDays: number;
  timesPerPeriod: number;
  dates: string[];
  excludedDates: string[];
}

function draftFrom(habit: HabitDTO | null, defaultDate: string): Draft {
  if (habit) {
    return {
      name: habit.name,
      icon: habit.icon ?? DEFAULT_HABIT_ICON,
      color: habit.color,
      goalType: habit.goalType,
      targetCount: habit.targetCount,
      targetSeconds: habit.targetSeconds || 30 * 60,
      categoryId: habit.categoryId,
      scheduleType: habit.scheduleType,
      weekdays: habit.weekdays.length ? habit.weekdays : [1, 2, 3, 4, 5],
      weekInterval: habit.weekInterval,
      intervalDays: habit.intervalDays,
      timesPerPeriod: habit.timesPerPeriod,
      dates: habit.dates.length ? habit.dates : [defaultDate],
      excludedDates: habit.excludedDates,
    };
  }
  return {
    name: "",
    icon: DEFAULT_HABIT_ICON,
    color: HABIT_COLORS[0],
    goalType: "TASK",
    targetCount: 3,
    targetSeconds: 30 * 60,
    categoryId: null,
    scheduleType: "DAILY",
    weekdays: [1, 2, 3, 4, 5],
    weekInterval: 1,
    intervalDays: 2,
    timesPerPeriod: 3,
    dates: [defaultDate],
    excludedDates: [],
  };
}

const GOAL_TYPES: { value: HabitGoalType; label: string; hint: string }[] = [
  { value: "TASK", label: "Task", hint: "Done or not" },
  { value: "COUNT", label: "Count", hint: "Reach a number" },
  { value: "TIME", label: "Time", hint: "Track a duration" },
];

export function HabitForm({
  open,
  habit,
  defaultDate,
  onClose,
}: {
  open: boolean;
  habit: HabitDTO | null;
  defaultDate: string;
  onClose: () => void;
}) {
  const { settings } = useSettings();
  const { categories } = useCategories();
  const [draft, setDraft] = useState<Draft>(() => draftFrom(habit, defaultDate));
  const [saving, setSaving] = useState(false);

  // Reset the draft whenever the sheet opens for a different habit.
  const syncKey = `${open}:${habit?.id ?? "new"}`;
  const [lastKey, setLastKey] = useState(syncKey);
  if (syncKey !== lastKey) {
    setLastKey(syncKey);
    setDraft(draftFrom(habit, defaultDate));
  }

  function patch(p: Partial<Draft>) {
    setDraft((d) => ({ ...d, ...p }));
  }

  function setGoalType(goalType: HabitGoalType) {
    patch({
      goalType,
      ...(goalType === "TIME" && draft.targetSeconds < 60 ? { targetSeconds: 30 * 60 } : {}),
    });
  }

  const hours = Math.floor(draft.targetSeconds / 3600);
  const minutes = Math.floor((draft.targetSeconds % 3600) / 60);

  const valid =
    draft.name.trim().length > 0 &&
    (draft.goalType !== "TIME" || draft.targetSeconds >= 60) &&
    (draft.scheduleType !== "WEEKDAYS" || draft.weekdays.length > 0) &&
    (draft.scheduleType !== "DATES" || draft.dates.length > 0);

  async function save() {
    if (!valid) return;
    setSaving(true);
    try {
      const payload = {
        name: draft.name.trim(),
        icon: draft.icon,
        color: draft.color,
        goalType: draft.goalType,
        targetCount: draft.targetCount,
        targetSeconds: draft.targetSeconds,
        categoryId: draft.goalType === "TIME" ? draft.categoryId : null,
        scheduleType: draft.scheduleType,
        weekdays: draft.weekdays,
        weekInterval: draft.weekInterval,
        intervalDays: draft.intervalDays,
        timesPerPeriod: draft.timesPerPeriod,
        dates: draft.dates,
        excludedDates: draft.excludedDates,
      };
      if (habit) {
        await updateHabit(habit.id, payload);
      } else {
        await createHabit({ ...payload, anchorDate: defaultDate });
      }
      onClose();
    } finally {
      setSaving(false);
    }
  }

  async function remove() {
    if (!habit) return;
    if (!confirm(`Delete “${habit.name}”? Past history is kept but it stops showing up.`)) {
      return;
    }
    setSaving(true);
    try {
      await archiveHabit(habit.id);
      onClose();
    } finally {
      setSaving(false);
    }
  }

  return (
    <Sheet
      open={open}
      onClose={onClose}
      title={habit ? "Edit habit" : "New habit"}
      footer={
        <div className="flex items-center justify-between gap-2">
          {habit ? (
            <button
              type="button"
              onClick={remove}
              disabled={saving}
              className="inline-flex items-center gap-1.5 rounded-lg px-2 py-1.5 text-sm text-muted hover:bg-red-500/10 hover:text-red-500"
            >
              <Trash2 className="h-4 w-4" />
              Delete
            </button>
          ) : (
            <span />
          )}
          <div className="flex items-center gap-2">
            <Button variant="ghost" size="sm" onClick={onClose}>
              Cancel
            </Button>
            <Button size="sm" onClick={save} disabled={!valid || saving}>
              {saving ? "Saving…" : habit ? "Save" : "Create"}
            </Button>
          </div>
        </div>
      }
    >
      <div className="flex flex-col gap-6">
        {/* identity */}
        <div className="flex items-center gap-3">
          <IconPicker
            value={draft.icon}
            color={draft.color}
            onChange={(icon) => patch({ icon })}
          />
          <Input
            value={draft.name}
            onChange={(e) => patch({ name: e.target.value })}
            placeholder="Habit name"
            autoFocus
            className="h-12"
          />
        </div>

        {/* color */}
        <Field label="Color">
          <div className="flex flex-wrap gap-2">
            {HABIT_COLORS.map((c) => (
              <button
                key={c}
                type="button"
                aria-label={c}
                onClick={() => patch({ color: c })}
                className={cn(
                  "h-7 w-7 rounded-full ring-2 ring-offset-2 ring-offset-surface transition-transform hover:scale-110",
                  draft.color === c ? "ring-foreground/40" : "ring-transparent",
                )}
                style={{ backgroundColor: c }}
              />
            ))}
          </div>
        </Field>

        {/* goal */}
        <Field label="Goal">
          <div className="grid grid-cols-3 gap-1.5">
            {GOAL_TYPES.map((g) => (
              <button
                key={g.value}
                type="button"
                onClick={() => setGoalType(g.value)}
                className={cn(
                  "flex flex-col items-center gap-0.5 rounded-xl border px-2 py-2.5 transition-colors",
                  draft.goalType === g.value
                    ? "border-primary bg-primary/10"
                    : "border-border hover:bg-surface-2",
                )}
              >
                <span className="text-sm font-medium">{g.label}</span>
                <span className="text-[11px] text-faint">{g.hint}</span>
              </button>
            ))}
          </div>

          {draft.goalType === "COUNT" && (
            <div className="mt-3 flex items-center justify-between">
              <span className="text-sm text-muted">Target count</span>
              <Stepper
                value={draft.targetCount}
                min={1}
                max={1000}
                onChange={(v) => patch({ targetCount: v })}
                format={(v) => `${v}×`}
                width="w-12"
              />
            </div>
          )}

          {draft.goalType === "TIME" && (
            <div className="mt-3 flex flex-col gap-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-muted">Duration</span>
                <div className="flex items-center gap-3">
                  <Stepper
                    value={hours}
                    min={0}
                    max={23}
                    onChange={(h) => patch({ targetSeconds: (h * 60 + minutes) * 60 })}
                    format={(v) => `${v}h`}
                    width="w-8"
                  />
                  <Stepper
                    value={minutes}
                    min={0}
                    max={55}
                    step={5}
                    onChange={(m) => patch({ targetSeconds: (hours * 60 + m) * 60 })}
                    format={(v) => `${v}m`}
                    width="w-10"
                  />
                </div>
              </div>
              <div className="flex items-center justify-between gap-3">
                <span className="text-sm text-muted">Track on category</span>
                <select
                  value={draft.categoryId ?? ""}
                  onChange={(e) => patch({ categoryId: e.target.value || null })}
                  className="h-9 max-w-[55%] rounded-lg border border-border bg-surface px-2 text-sm focus:border-primary focus:outline-none"
                >
                  <option value="">Standalone timer</option>
                  {categories
                    .filter((c) => !c.archived)
                    .map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                </select>
              </div>
              <p className="-mt-1 text-xs text-faint">
                {draft.categoryId
                  ? "Timer logs real tracked time and counts that category’s time toward the goal."
                  : "A standalone timer that doesn’t touch your reports."}
              </p>
            </div>
          )}
        </Field>

        {/* schedule */}
        <Field label="Repeat">
          <SchedulePicker
            value={draft}
            weekStartsOn={settings.weekStartsOn}
            onChange={patch}
          />
        </Field>
      </div>
    </Sheet>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-2">
      <span className="text-xs font-medium uppercase tracking-wide text-faint">
        {label}
      </span>
      {children}
    </div>
  );
}
