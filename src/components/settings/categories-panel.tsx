"use client";

import { Archive, Check, Plus, RotateCcw, Trash2 } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import {
  createCategory,
  deleteCategory,
  updateCategory,
  useCategories,
} from "@/lib/client/use-categories";
import { cn } from "@/lib/cn";
import type { CategoryDTO } from "@/lib/types";

const PALETTE = [
  "#6366f1", "#ec4899", "#f59e0b", "#10b981", "#3b82f6",
  "#8b5cf6", "#ef4444", "#14b8a6", "#f97316", "#06b6d4",
];

function ColorPicker({
  value,
  onChange,
}: {
  value: string;
  onChange: (color: string) => void;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    function onDoc(e: MouseEvent) {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, [open]);

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        aria-label="Change color"
        onClick={() => setOpen((o) => !o)}
        className="h-5 w-5 shrink-0 rounded-full ring-1 ring-inset ring-black/10 transition-transform hover:scale-110"
        style={{ backgroundColor: value }}
      />
      {open && (
        <div className="absolute left-0 top-7 z-20 grid grid-cols-5 gap-1.5 rounded-xl border border-border bg-surface p-2 shadow-lg">
          {PALETTE.map((c) => (
            <button
              key={c}
              type="button"
              aria-label={c}
              onClick={() => {
                onChange(c);
                setOpen(false);
              }}
              className="grid h-6 w-6 place-items-center rounded-full ring-1 ring-inset ring-black/10 transition-transform hover:scale-110"
              style={{ backgroundColor: c }}
            >
              {c.toLowerCase() === value.toLowerCase() && (
                <Check className="h-3 w-3 text-white" strokeWidth={3} />
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}

function CategoryRow({
  category,
  onChanged,
}: {
  category: CategoryDTO;
  onChanged: () => void;
}) {
  const [name, setName] = useState(category.name);
  const [busy, setBusy] = useState(false);

  async function saveName() {
    const trimmed = name.trim();
    if (!trimmed || trimmed === category.name) {
      setName(category.name);
      return;
    }
    setBusy(true);
    try {
      await updateCategory(category.id, { name: trimmed });
      onChanged();
    } finally {
      setBusy(false);
    }
  }

  async function setColor(color: string) {
    await updateCategory(category.id, { color });
    onChanged();
  }

  async function setArchived(archived: boolean) {
    setBusy(true);
    try {
      await updateCategory(category.id, { archived });
      onChanged();
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!confirm(`Delete “${category.name}” permanently? Its time entries will become uncategorized.`)) {
      return;
    }
    setBusy(true);
    try {
      await deleteCategory(category.id);
      onChanged();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div
      className={cn(
        "flex items-center gap-3 rounded-xl border border-border bg-surface px-3 py-2",
        category.archived && "opacity-60",
      )}
    >
      <ColorPicker value={category.color} onChange={setColor} />
      <input
        value={name}
        disabled={busy || category.archived}
        onChange={(e) => setName(e.target.value)}
        onBlur={saveName}
        onKeyDown={(e) => {
          if (e.key === "Enter") e.currentTarget.blur();
          if (e.key === "Escape") setName(category.name);
        }}
        className="min-w-0 flex-1 bg-transparent text-sm focus:outline-none disabled:cursor-default"
      />
      {category.archived ? (
        <>
          <button
            type="button"
            onClick={() => setArchived(false)}
            disabled={busy}
            className="flex items-center gap-1 rounded-lg px-2 py-1 text-xs text-muted hover:bg-surface-2 hover:text-foreground"
          >
            <RotateCcw className="h-3.5 w-3.5" />
            Restore
          </button>
          <button
            type="button"
            aria-label="Delete permanently"
            onClick={remove}
            disabled={busy}
            className="grid h-7 w-7 place-items-center rounded-lg text-faint hover:bg-red-500/10 hover:text-red-500"
          >
            <Trash2 className="h-3.5 w-3.5" />
          </button>
        </>
      ) : (
        <button
          type="button"
          aria-label={`Archive ${category.name}`}
          title="Archive"
          onClick={() => setArchived(true)}
          disabled={busy}
          className="grid h-7 w-7 place-items-center rounded-lg text-faint hover:bg-surface-2 hover:text-foreground"
        >
          <Archive className="h-3.5 w-3.5" />
        </button>
      )}
    </div>
  );
}

export function CategoriesPanel() {
  const { categories, isLoading, mutate } = useCategories();
  const [newName, setNewName] = useState("");
  const [newColor, setNewColor] = useState(PALETTE[0]);
  const [adding, setAdding] = useState(false);
  const [showArchived, setShowArchived] = useState(false);

  const active = categories.filter((c) => !c.archived);
  const archived = categories.filter((c) => c.archived);

  async function handleAdd() {
    const name = newName.trim();
    if (!name) return;
    setAdding(true);
    try {
      await createCategory(name, newColor);
      await mutate();
      setNewName("");
      setNewColor(PALETTE[(PALETTE.indexOf(newColor) + 1) % PALETTE.length]);
    } finally {
      setAdding(false);
    }
  }

  if (isLoading) {
    return <div className="h-32 animate-pulse rounded-2xl bg-surface-2" />;
  }

  return (
    <div className="flex flex-col gap-3">
      {active.length > 0 && (
        <div className="flex flex-col gap-2">
          {active.map((c) => (
            <CategoryRow key={c.id} category={c} onChanged={() => mutate()} />
          ))}
        </div>
      )}

      {/* add new */}
      <div className="flex items-center gap-2 rounded-xl border border-dashed border-border px-3 py-2">
        <ColorPicker value={newColor} onChange={setNewColor} />
        <input
          value={newName}
          onChange={(e) => setNewName(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") handleAdd();
          }}
          placeholder="New category…"
          className="min-w-0 flex-1 bg-transparent text-sm placeholder:text-faint focus:outline-none"
        />
        <Button size="sm" onClick={handleAdd} disabled={adding || !newName.trim()}>
          <Plus className="h-3.5 w-3.5" />
          Add
        </Button>
      </div>

      {archived.length > 0 && (
        <div className="mt-1">
          <button
            type="button"
            onClick={() => setShowArchived((s) => !s)}
            className="text-xs font-medium text-faint hover:text-muted"
          >
            {showArchived ? "Hide" : "Show"} archived ({archived.length})
          </button>
          {showArchived && (
            <div className="mt-2 flex flex-col gap-2">
              {archived.map((c) => (
                <CategoryRow key={c.id} category={c} onChanged={() => mutate()} />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
