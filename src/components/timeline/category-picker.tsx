"use client";

import { Check, Plus, Tag } from "lucide-react";
import { useRef, useState } from "react";
import { useClickOutside } from "@/lib/client/use-click-outside";
import { cn } from "@/lib/cn";
import type { CategoryDTO } from "@/lib/types";

export function CategoryDot({
  color,
  className,
}: {
  color: string;
  className?: string;
}) {
  return (
    <span
      className={cn("inline-block h-2.5 w-2.5 shrink-0 rounded-full", className)}
      style={{ backgroundColor: color }}
    />
  );
}

export function CategoryPicker({
  categories,
  value,
  onChange,
  onCreate,
  size = "md",
}: {
  categories: CategoryDTO[];
  value: string | null;
  onChange: (categoryId: string | null) => void;
  onCreate: (name: string) => Promise<CategoryDTO>;
  size?: "sm" | "md";
}) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [creating, setCreating] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useClickOutside(ref, () => setOpen(false), open);

  const selected = categories.find((c) => c.id === value) ?? null;
  const filtered = categories.filter((c) =>
    c.name.toLowerCase().includes(query.trim().toLowerCase()),
  );
  const exactMatch = categories.some(
    (c) => c.name.toLowerCase() === query.trim().toLowerCase(),
  );

  async function handleCreate() {
    const name = query.trim();
    if (!name || creating) return;
    setCreating(true);
    try {
      const cat = await onCreate(name);
      onChange(cat.id);
      setQuery("");
      setOpen(false);
    } finally {
      setCreating(false);
    }
  }

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className={cn(
          "inline-flex items-center gap-2 rounded-full border border-border bg-surface text-muted transition-colors hover:border-border-strong",
          size === "sm" ? "h-8 px-3 text-xs" : "h-9 px-3.5 text-sm",
        )}
      >
        {selected ? (
          <>
            <CategoryDot color={selected.color} />
            <span className="max-w-[10rem] truncate text-foreground">
              {selected.name}
            </span>
          </>
        ) : (
          <>
            <Tag className="h-3.5 w-3.5" />
            <span>Category</span>
          </>
        )}
      </button>

      {open && (
        <div className="absolute right-0 top-full z-40 mt-2 w-60 overflow-hidden rounded-xl border border-border bg-surface shadow-lg">
          <div className="border-b border-border p-2">
            <input
              autoFocus
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && query.trim() && !exactMatch) {
                  e.preventDefault();
                  void handleCreate();
                }
              }}
              placeholder="Search or create…"
              className="h-8 w-full bg-transparent px-2 text-sm placeholder:text-faint focus:outline-none"
            />
          </div>

          <div className="max-h-60 overflow-y-auto py-1">
            {value && (
              <button
                type="button"
                onClick={() => {
                  onChange(null);
                  setOpen(false);
                }}
                className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-muted hover:bg-surface-2"
              >
                <Tag className="h-3.5 w-3.5" />
                No category
              </button>
            )}

            {filtered.map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() => {
                  onChange(c.id);
                  setOpen(false);
                }}
                className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm hover:bg-surface-2"
              >
                <CategoryDot color={c.color} />
                <span className="flex-1 truncate">{c.name}</span>
                {c.id === value && <Check className="h-3.5 w-3.5 text-primary" />}
              </button>
            ))}

            {query.trim() && !exactMatch && (
              <button
                type="button"
                onClick={handleCreate}
                disabled={creating}
                className="flex w-full items-center gap-2 px-3 py-2 text-left text-sm text-primary hover:bg-surface-2 disabled:opacity-50"
              >
                <Plus className="h-3.5 w-3.5" />
                Create “{query.trim()}”
              </button>
            )}

            {filtered.length === 0 && !query.trim() && (
              <p className="px-3 py-2 text-sm text-faint">No categories yet</p>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
