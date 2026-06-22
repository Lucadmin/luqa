"use client";

import { Trash2 } from "lucide-react";
import { useState } from "react";
import { CategoryPicker } from "@/components/timeline/category-picker";
import { TimeDial } from "@/components/timeline/time-dial";
import type { EntryDraft } from "@/components/timeline/types";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import type { CategoryDTO } from "@/lib/types";

export interface SaveResult {
  description: string;
  categoryId: string | null;
  startMin: number;
  endMin: number;
  /** Remaining gap below this entry, if any (for chained gap-filling). */
  nextGap: { startMin: number; endMin: number } | null;
}

export function EntryEditor({
  draft,
  categories,
  onSave,
  onDelete,
  onClose,
  onCreateCategory,
  saving,
}: {
  draft: EntryDraft;
  categories: CategoryDTO[];
  onSave: (result: SaveResult) => void;
  onDelete?: () => void;
  onClose: () => void;
  onCreateCategory: (name: string) => Promise<CategoryDTO>;
  saving: boolean;
}) {
  const [description, setDescription] = useState(draft.description);
  const [categoryId, setCategoryId] = useState(draft.categoryId);
  const [startMin, setStartMin] = useState(draft.startMin);
  const [endMin, setEndMin] = useState(draft.endMin);

  const isEdit = Boolean(draft.id);

  function handleSave() {
    // If this entry came from a gap and doesn't reach the gap's end,
    // the leftover below becomes the next gap to fill.
    let nextGap: SaveResult["nextGap"] = null;
    if (draft.gapEndMin !== undefined && endMin < draft.gapEndMin) {
      nextGap = { startMin: endMin, endMin: draft.gapEndMin };
    }
    onSave({ description, categoryId, startMin, endMin, nextGap });
  }

  return (
    <Sheet
      open
      onClose={onClose}
      title={isEdit ? "Edit entry" : "New entry"}
      footer={
        <div className="flex items-center justify-between gap-3">
          {isEdit && onDelete ? (
            <Button variant="ghost" onClick={onDelete} className="text-red-500">
              <Trash2 className="h-4 w-4" />
              Delete
            </Button>
          ) : (
            <span />
          )}
          <Button onClick={handleSave} disabled={saving}>
            {saving ? "Saving…" : isEdit ? "Save" : "Add entry"}
          </Button>
        </div>
      }
    >
      <div className="flex flex-col gap-5">
        <Input
          autoFocus
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="What were you doing?"
        />

        <div>
          <CategoryPicker
            categories={categories}
            value={categoryId}
            onChange={setCategoryId}
            onCreate={onCreateCategory}
          />
        </div>

        <div className="pt-1">
          <TimeDial
            startMin={startMin}
            endMin={endMin}
            onChange={(s, e) => {
              setStartMin(s);
              setEndMin(e);
            }}
          />
        </div>
      </div>
    </Sheet>
  );
}
