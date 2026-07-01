"use client";

import { Flag, Star, Trash2 } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import { cn } from "@/lib/cn";
import type { WeekNoteDTO } from "@/lib/types";

interface WeekNoteSheetProps {
  weekIndex: number | null;
  note: WeekNoteDTO | undefined;
  /** Human label, e.g. "Age 27 · week 12". */
  headline: string;
  /** e.g. "12 May – 18 May 2027". */
  dateRange: string;
  /** Names of periods covering this week. */
  periodNames: string[];
  onClose: () => void;
  onSave: (note: WeekNoteDTO) => Promise<void>;
}

const textareaClass =
  "min-h-[90px] w-full resize-y rounded-xl border border-border bg-surface px-3.5 py-2.5 text-sm placeholder:text-faint focus-visible:outline-none focus-visible:border-primary focus-visible:ring-2 focus-visible:ring-ring/30 transition-colors";

export function WeekNoteSheet({
  weekIndex,
  note,
  headline,
  dateRange,
  periodNames,
  onClose,
  onSave,
}: WeekNoteSheetProps) {
  const [highlights, setHighlights] = useState("");
  const [lessons, setLessons] = useState("");
  const [rating, setRating] = useState<number | null>(null);
  const [milestone, setMilestone] = useState("");
  const [saving, setSaving] = useState(false);

  // Re-seed the form whenever a different week is opened (render-time sync).
  const [seed, setSeed] = useState<number | null>(null);
  if (weekIndex !== seed) {
    setSeed(weekIndex);
    setHighlights(note?.highlights ?? "");
    setLessons(note?.lessons ?? "");
    setRating(note?.rating ?? null);
    setMilestone(note?.milestone ?? "");
  }

  async function persist(payload: WeekNoteDTO) {
    setSaving(true);
    try {
      await onSave(payload);
      onClose();
    } finally {
      setSaving(false);
    }
  }

  async function save() {
    if (weekIndex === null) return;
    await persist({
      weekIndex,
      highlights: highlights.trim(),
      lessons: lessons.trim(),
      rating,
      milestone: milestone.trim() || null,
    });
  }

  async function clear() {
    if (weekIndex === null) return;
    await persist({ weekIndex, highlights: "", lessons: "", rating: null, milestone: null });
  }

  const hasExisting = Boolean(note);

  return (
    <Sheet open={weekIndex !== null} onClose={onClose} title="Weekly review">
      <div className="flex flex-col gap-5">
        <div>
          <p className="text-sm font-semibold">{headline}</p>
          <p className="mt-0.5 text-xs text-faint">{dateRange}</p>
          {periodNames.length > 0 && (
            <div className="mt-2 flex flex-wrap gap-1.5">
              {periodNames.map((n) => (
                <span
                  key={n}
                  className="rounded-full bg-surface-2 px-2 py-0.5 text-[11px] text-muted"
                >
                  {n}
                </span>
              ))}
            </div>
          )}
        </div>

        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-muted">Highlights & wins</span>
          <textarea
            value={highlights}
            onChange={(e) => setHighlights(e.target.value)}
            placeholder="What went well? What did you accomplish?"
            className={textareaClass}
          />
        </label>

        <label className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-muted">Lessons & retrospective</span>
          <textarea
            value={lessons}
            onChange={(e) => setLessons(e.target.value)}
            placeholder="What did you learn? What would you do differently?"
            className={textareaClass}
          />
        </label>

        <div className="flex flex-col gap-1.5">
          <span className="text-xs font-medium text-muted">How was the week?</span>
          <div className="flex items-center gap-1.5">
            {[1, 2, 3, 4, 5].map((n) => (
              <button
                key={n}
                type="button"
                aria-label={`Rate ${n}`}
                onClick={() => setRating(rating === n ? null : n)}
                className={cn(
                  "grid h-9 w-9 place-items-center rounded-lg border transition-colors",
                  rating !== null && n <= rating
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-border text-faint hover:text-muted",
                )}
              >
                <Star
                  className="h-4 w-4"
                  fill={rating !== null && n <= rating ? "currentColor" : "none"}
                />
              </button>
            ))}
            {rating !== null && (
              <button
                type="button"
                onClick={() => setRating(null)}
                className="ml-1 text-xs text-faint hover:text-muted"
              >
                clear
              </button>
            )}
          </div>
        </div>

        <label className="flex flex-col gap-1.5">
          <span className="flex items-center gap-1.5 text-xs font-medium text-muted">
            <Flag className="h-3.5 w-3.5" /> Milestone (optional)
          </span>
          <Input
            value={milestone}
            onChange={(e) => setMilestone(e.target.value)}
            placeholder="e.g. Graduated, Moved to Berlin"
            className="h-10"
          />
          <span className="text-[11px] text-faint">
            Adds a marker dot to this week on the grid.
          </span>
        </label>

        <div className="flex items-center justify-between gap-2 pt-1">
          {hasExisting ? (
            <Button
              variant="ghost"
              size="sm"
              onClick={clear}
              disabled={saving}
              className="text-muted hover:text-red-500"
            >
              <Trash2 className="h-3.5 w-3.5" /> Clear
            </Button>
          ) : (
            <span />
          )}
          <div className="flex items-center gap-2">
            <Button variant="secondary" size="sm" onClick={onClose} disabled={saving}>
              Cancel
            </Button>
            <Button size="sm" onClick={save} disabled={saving}>
              {saving ? "Saving…" : "Save"}
            </Button>
          </div>
        </div>
      </div>
    </Sheet>
  );
}
