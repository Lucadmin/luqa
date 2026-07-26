"use client";

import { Minus, Plus } from "lucide-react";
import { useState } from "react";
import { ThemeToggle } from "@/components/theme-toggle";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { useSettings } from "@/lib/client/use-settings";
import { cn } from "@/lib/cn";
import { formatClock, formatDuration } from "@/lib/time";

/** One labelled settings row: text on the left, a control on the right. */
function Row({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: React.ReactNode;
}) {
  return (
    <div className="flex items-center justify-between gap-4 px-4 py-3.5">
      <div className="min-w-0">
        <p className="text-sm font-medium">{label}</p>
        {hint && <p className="mt-0.5 text-xs text-faint">{hint}</p>}
      </div>
      <div className="shrink-0">{children}</div>
    </div>
  );
}

function Card({ children }: { children: React.ReactNode }) {
  return (
    <div className="divide-y divide-border rounded-2xl border border-border bg-surface">
      {children}
    </div>
  );
}

export function ProfilePanel() {
  const { settings, updateSettings } = useSettings();
  const [name, setName] = useState(settings.name ?? "");
  const [saving, setSaving] = useState(false);

  // Adopt the loaded/saved name when it changes upstream (e.g. once the
  // settings request resolves) — the render-time sync pattern, no effect.
  const [lastLoaded, setLastLoaded] = useState(settings.name);
  if (settings.name !== lastLoaded) {
    setLastLoaded(settings.name);
    setName(settings.name ?? "");
  }

  const dirty = name.trim() !== (settings.name ?? "");

  async function save() {
    setSaving(true);
    try {
      await updateSettings({ name: name.trim() || null });
    } finally {
      setSaving(false);
    }
  }

  return (
    <Card>
      <Row label="Name" hint="Shown in the sidebar.">
        <div className="flex items-center gap-2">
          <Input
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Your name"
            className="h-9 w-44"
          />
          <Button size="sm" onClick={save} disabled={!dirty || saving}>
            Save
          </Button>
        </div>
      </Row>
      <Row label="Email">
        <span className="text-sm text-muted">{settings.email}</span>
      </Row>
    </Card>
  );
}

const GOAL_MIN = 0;
const GOAL_MAX = 16 * 60;
const GOAL_STEP = 30;

const LIFE_MIN = 40;
const LIFE_MAX = 150;
const LIFE_STEP = 5;

const CURRENCIES = [
  { code: "EUR", label: "€ Euro" },
  { code: "USD", label: "$ US dollar" },
  { code: "GBP", label: "£ Pound" },
  { code: "CHF", label: "CHF Swiss franc" },
  { code: "SEK", label: "kr Swedish krona" },
  { code: "PLN", label: "zł Złoty" },
];

export function PreferencesPanel() {
  const { settings, updateSettings } = useSettings();

  return (
    <Card>
      <Row
        label="My day starts at"
        hint="Time logged before this hour counts toward the previous day."
      >
        <select
          value={settings.dayStartHour}
          onChange={(e) => updateSettings({ dayStartHour: Number(e.target.value) })}
          className="h-9 rounded-lg border border-border bg-surface px-2 text-sm tabular-nums focus:outline-none focus-visible:border-primary"
        >
          {Array.from({ length: 10 }, (_, h) => (
            <option key={h} value={h}>
              {formatClock(h * 60)}
              {h === 3 ? " (default)" : ""}
            </option>
          ))}
        </select>
      </Row>

      <Row label="Daily goal" hint="Drawn as the reference line on reports.">
        <div className="flex items-center gap-2">
          <button
            type="button"
            aria-label="Decrease goal"
            onClick={() =>
              updateSettings({
                dailyGoalMinutes: Math.max(GOAL_MIN, settings.dailyGoalMinutes - GOAL_STEP),
              })
            }
            disabled={settings.dailyGoalMinutes <= GOAL_MIN}
            className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <Minus className="h-3.5 w-3.5" />
          </button>
          <span className="w-14 text-center text-sm font-medium tabular-nums">
            {settings.dailyGoalMinutes > 0 ? formatDuration(settings.dailyGoalMinutes) : "Off"}
          </span>
          <button
            type="button"
            aria-label="Increase goal"
            onClick={() =>
              updateSettings({
                dailyGoalMinutes: Math.min(GOAL_MAX, settings.dailyGoalMinutes + GOAL_STEP),
              })
            }
            disabled={settings.dailyGoalMinutes >= GOAL_MAX}
            className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <Plus className="h-3.5 w-3.5" />
          </button>
        </div>
      </Row>

      <Row label="Currency" hint="Used everywhere amounts are shown.">
        <select
          value={settings.currency}
          onChange={(e) => updateSettings({ currency: e.target.value })}
          className="h-9 rounded-lg border border-border bg-surface px-2 text-sm focus:outline-none focus-visible:border-primary"
        >
          {CURRENCIES.map(({ code, label }) => (
            <option key={code} value={code}>
              {label}
            </option>
          ))}
        </select>
      </Row>

      <Row label="Week starts on">
        <div className="inline-flex items-center gap-0.5 rounded-full border border-border bg-surface p-0.5">
          {[
            { value: 1, label: "Monday" },
            { value: 0, label: "Sunday" },
          ].map(({ value, label }) => (
            <button
              key={value}
              type="button"
              onClick={() => updateSettings({ weekStartsOn: value })}
              className={cn(
                "rounded-full px-3 py-1 text-xs font-medium transition-colors",
                settings.weekStartsOn === value
                  ? "bg-surface-2 text-foreground"
                  : "text-faint hover:text-muted",
              )}
            >
              {label}
            </button>
          ))}
        </div>
      </Row>

      <Row
        label="Date of birth"
        hint="Anchors your life overview grid."
      >
        <input
          type="date"
          value={settings.birthDate ?? ""}
          max={new Date().toISOString().slice(0, 10)}
          onChange={(e) => updateSettings({ birthDate: e.target.value || null })}
          className="h-9 rounded-lg border border-border bg-surface px-2 text-sm tabular-nums focus:outline-none focus-visible:border-primary"
        />
      </Row>

      <Row label="Life span" hint="How many years the life grid shows.">
        <div className="flex items-center gap-2">
          <button
            type="button"
            aria-label="Decrease life span"
            onClick={() =>
              updateSettings({
                lifeExpectancyYears: Math.max(LIFE_MIN, settings.lifeExpectancyYears - LIFE_STEP),
              })
            }
            disabled={settings.lifeExpectancyYears <= LIFE_MIN}
            className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <Minus className="h-3.5 w-3.5" />
          </button>
          <span className="w-16 text-center text-sm font-medium tabular-nums">
            {settings.lifeExpectancyYears} yrs
          </span>
          <button
            type="button"
            aria-label="Increase life span"
            onClick={() =>
              updateSettings({
                lifeExpectancyYears: Math.min(LIFE_MAX, settings.lifeExpectancyYears + LIFE_STEP),
              })
            }
            disabled={settings.lifeExpectancyYears >= LIFE_MAX}
            className="grid h-8 w-8 place-items-center rounded-lg border border-border text-muted hover:bg-surface-2 hover:text-foreground disabled:opacity-40"
          >
            <Plus className="h-3.5 w-3.5" />
          </button>
        </div>
      </Row>

      <Row label="Appearance">
        <ThemeToggle />
      </Row>
    </Card>
  );
}
