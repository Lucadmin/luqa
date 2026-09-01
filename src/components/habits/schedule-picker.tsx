"use client";

import { X } from "lucide-react";
import { cn } from "@/lib/cn";
import type { HabitScheduleType } from "@/lib/types";
import { Stepper } from "./stepper";

export interface ScheduleValue {
  scheduleType: HabitScheduleType;
  weekdays: number[];
  weekInterval: number;
  intervalDays: number;
  intervalFromLastDone: boolean;
  timesPerPeriod: number;
  dates: string[];
  excludedDates: string[];
}

const TYPES: { value: HabitScheduleType; label: string }[] = [
  { value: "DAILY", label: "Daily" },
  { value: "WEEKDAYS", label: "Specific days" },
  { value: "INTERVAL", label: "Every few days" },
  { value: "TIMES_PER_WEEK", label: "Times / week" },
  { value: "TIMES_PER_MONTH", label: "Times / month" },
  { value: "TIMES_PER_YEAR", label: "Times / year" },
  { value: "DATES", label: "Specific dates" },
];

const FULL_WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

export function SchedulePicker({
  value,
  weekStartsOn,
  onChange,
}: {
  value: ScheduleValue;
  weekStartsOn: number;
  onChange: (patch: Partial<ScheduleValue>) => void;
}) {
  const orderedDays = Array.from({ length: 7 }, (_, i) => (weekStartsOn + i) % 7);

  function toggleDay(day: number) {
    const set = new Set(value.weekdays);
    if (set.has(day)) set.delete(day);
    else set.add(day);
    onChange({ weekdays: [...set].sort((a, b) => a - b) });
  }

  const periodWord =
    value.scheduleType === "TIMES_PER_WEEK"
      ? "week"
      : value.scheduleType === "TIMES_PER_MONTH"
        ? "month"
        : "year";
  const periodMax =
    value.scheduleType === "TIMES_PER_WEEK"
      ? 7
      : value.scheduleType === "TIMES_PER_MONTH"
        ? 31
        : 366;

  return (
    <div className="flex flex-col gap-3">
      {/* type selector */}
      <div className="grid grid-cols-2 gap-1.5">
        {TYPES.map((t) => (
          <button
            key={t.value}
            type="button"
            onClick={() => onChange({ scheduleType: t.value })}
            className={cn(
              "rounded-lg border px-3 py-2 text-sm font-medium transition-colors",
              value.scheduleType === t.value
                ? "border-primary bg-primary/10 text-primary"
                : "border-border text-muted hover:bg-surface-2 hover:text-foreground",
            )}
          >
            {t.label}
          </button>
        ))}
      </div>

      {/* type-specific detail */}
      {value.scheduleType === "WEEKDAYS" && (
        <div className="flex flex-col gap-3 rounded-xl border border-border p-3">
          <div className="flex justify-between gap-1">
            {orderedDays.map((day) => {
              const on = value.weekdays.includes(day);
              return (
                <button
                  key={day}
                  type="button"
                  onClick={() => toggleDay(day)}
                  className={cn(
                    "grid h-9 w-9 place-items-center rounded-full text-xs font-semibold transition-colors",
                    on
                      ? "bg-primary text-primary-foreground"
                      : "bg-surface-2 text-muted hover:text-foreground",
                  )}
                >
                  {FULL_WEEKDAYS[day][0]}
                </button>
              );
            })}
          </div>
          <Row label="Repeat every">
            <Stepper
              value={value.weekInterval}
              min={1}
              max={12}
              onChange={(v) => onChange({ weekInterval: v })}
              format={(v) => (v === 1 ? "week" : `${v} wks`)}
              width="w-16"
            />
          </Row>
        </div>
      )}

      {value.scheduleType === "INTERVAL" && (
        <div className="flex flex-col gap-3 rounded-xl border border-border p-3">
          <Row label="Repeat every">
            <Stepper
              value={value.intervalDays}
              min={1}
              max={365}
              onChange={(v) => onChange({ intervalDays: v })}
              format={(v) => (v === 1 ? "day" : `${v} days`)}
              width="w-16"
            />
          </Row>
          {value.intervalDays > 1 && (
            <div className="flex flex-col gap-1.5">
              <div className="grid grid-cols-2 gap-1.5">
                {[
                  { rolling: false, label: "Fixed days" },
                  { rolling: true, label: "From the last time" },
                ].map((option) => (
                  <button
                    key={option.label}
                    type="button"
                    onClick={() =>
                      onChange({ intervalFromLastDone: option.rolling })
                    }
                    className={cn(
                      "rounded-lg border px-3 py-2 text-sm font-medium transition-colors",
                      value.intervalFromLastDone === option.rolling
                        ? "border-primary bg-primary/10 text-primary"
                        : "border-border text-muted hover:bg-surface-2 hover:text-foreground",
                    )}
                  >
                    {option.label}
                  </button>
                ))}
              </div>
              <p className="text-xs text-faint">
                {value.intervalFromLastDone
                  ? `Due again ${value.intervalDays} days after each time you do it. Miss one and the whole cycle shifts.`
                  : `Every ${value.intervalDays} days from the start date, whether or not you kept up.`}
              </p>
            </div>
          )}
        </div>
      )}

      {(value.scheduleType === "TIMES_PER_WEEK" ||
        value.scheduleType === "TIMES_PER_MONTH" ||
        value.scheduleType === "TIMES_PER_YEAR") && (
        <Row label={`Times per ${periodWord}`}>
          <Stepper
            value={value.timesPerPeriod}
            min={1}
            max={periodMax}
            onChange={(v) => onChange({ timesPerPeriod: v })}
            width="w-10"
          />
        </Row>
      )}

      {value.scheduleType === "DATES" && (
        <DateList
          label="On these dates"
          dates={value.dates}
          onChange={(dates) => onChange({ dates })}
        />
      )}

      {/* excluded dates apply to every recurring schedule */}
      {value.scheduleType !== "DATES" && (
        <DateList
          label="Skip dates"
          dates={value.excludedDates}
          onChange={(excludedDates) => onChange({ excludedDates })}
          subtle
        />
      )}
    </div>
  );
}

function Row({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-center justify-between gap-3">
      <span className="text-sm text-muted">{label}</span>
      {children}
    </div>
  );
}

function DateList({
  label,
  dates,
  onChange,
  subtle,
}: {
  label: string;
  dates: string[];
  onChange: (dates: string[]) => void;
  subtle?: boolean;
}) {
  function add(value: string) {
    if (!value || dates.includes(value)) return;
    onChange([...dates, value].sort());
  }
  return (
    <div className="flex flex-col gap-2">
      <span className={cn("text-sm", subtle ? "text-faint" : "text-muted")}>{label}</span>
      <div className="flex flex-wrap items-center gap-1.5">
        {dates.map((d) => (
          <span
            key={d}
            className="inline-flex items-center gap-1 rounded-full bg-surface-2 px-2.5 py-1 text-xs tabular-nums"
          >
            {d}
            <button
              type="button"
              aria-label={`Remove ${d}`}
              onClick={() => onChange(dates.filter((x) => x !== d))}
              className="text-faint hover:text-foreground"
            >
              <X className="h-3 w-3" />
            </button>
          </span>
        ))}
        <input
          type="date"
          onChange={(e) => {
            add(e.target.value);
            e.target.value = "";
          }}
          className="h-8 rounded-lg border border-border bg-surface px-2 text-xs text-muted focus:border-primary focus:outline-none"
        />
      </div>
    </div>
  );
}
