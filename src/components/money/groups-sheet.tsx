"use client";

import { Check, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { Avatar } from "@/components/money/avatar";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import { createGroup, deleteGroup, updateGroup } from "@/lib/client/use-money";
import { cn } from "@/lib/cn";
import { PERSON_PALETTE } from "@/lib/money";
import type { PersonDTO, PersonGroupDTO } from "@/lib/types";

/** Manage the sets of people that get picked together — the flat, the trip. */
export function GroupsSheet({
  open,
  onClose,
  groups,
  people,
}: {
  open: boolean;
  onClose: () => void;
  groups: PersonGroupDTO[];
  people: PersonDTO[];
}) {
  const [editing, setEditing] = useState<PersonGroupDTO | null>(null);
  const [creating, setCreating] = useState(false);

  const [lastOpen, setLastOpen] = useState(open);
  if (open !== lastOpen) {
    setLastOpen(open);
    if (open) {
      setEditing(null);
      setCreating(false);
    }
  }

  return (
    <Sheet open={open} onClose={onClose} title="Groups">
      {editing || creating ? (
        <GroupForm
          group={editing}
          people={people}
          onDone={() => {
            setEditing(null);
            setCreating(false);
          }}
        />
      ) : (
        <div className="flex flex-col gap-2">
          {groups.length === 0 && (
            <p className="py-4 text-center text-sm text-faint">
              A group is a shortcut: pick it once and everyone in it lands on the
              bill.
            </p>
          )}

          {groups.map((g) => (
            <button
              key={g.id}
              type="button"
              onClick={() => setEditing(g)}
              className="flex items-center gap-3 rounded-xl border border-border px-3 py-2.5 text-left hover:bg-surface-2"
            >
              <Avatar name={g.name} color={g.color} emoji={g.emoji || "👥"} />
              <span className="min-w-0 flex-1">
                <span className="block truncate text-sm font-medium">{g.name}</span>
                <span className="block text-xs text-faint">
                  {g.memberIds.length} {g.memberIds.length === 1 ? "person" : "people"}
                </span>
              </span>
            </button>
          ))}

          <Button
            variant="secondary"
            className="mt-1"
            onClick={() => setCreating(true)}
            disabled={people.length === 0}
          >
            <Plus className="h-4 w-4" />
            New group
          </Button>
          {people.length === 0 && (
            <p className="text-center text-xs text-faint">Add some people first.</p>
          )}
        </div>
      )}
    </Sheet>
  );
}

function GroupForm({
  group,
  people,
  onDone,
}: {
  group: PersonGroupDTO | null;
  people: PersonDTO[];
  onDone: () => void;
}) {
  const [name, setName] = useState(group?.name ?? "");
  const [emoji, setEmoji] = useState(group?.emoji ?? "");
  const [color, setColor] = useState(group?.color ?? PERSON_PALETTE[0]);
  const [memberIds, setMemberIds] = useState<string[]>(group?.memberIds ?? []);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function save() {
    if (!name.trim()) {
      setError("Give the group a name");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const payload = { name: name.trim(), emoji: emoji.trim() || null, color, memberIds };
      if (group) await updateGroup(group.id, payload);
      else await createGroup(payload);
      onDone();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save that");
    } finally {
      setBusy(false);
    }
  }

  async function remove() {
    if (!group) return;
    setBusy(true);
    try {
      await deleteGroup(group.id);
      onDone();
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-2">
        <Input
          value={emoji}
          onChange={(e) => setEmoji(e.target.value)}
          placeholder="👥"
          aria-label="Emoji"
          maxLength={4}
          className="w-14 text-center"
        />
        <Input
          autoFocus
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Group name"
          aria-label="Group name"
          className="flex-1"
        />
      </div>

      <div className="flex flex-wrap gap-1.5">
        {PERSON_PALETTE.map((c) => (
          <button
            key={c}
            type="button"
            aria-label={`Colour ${c}`}
            onClick={() => setColor(c)}
            style={{ backgroundColor: c }}
            className={cn(
              "h-6 w-6 rounded-full transition-transform",
              color === c
                ? "ring-2 ring-foreground ring-offset-2 ring-offset-surface"
                : "hover:scale-110",
            )}
          />
        ))}
      </div>

      <div className="flex flex-col gap-2">
        <p className="text-xs font-medium uppercase tracking-wide text-faint">
          Members
        </p>
        <div className="flex flex-wrap gap-1.5">
          {people
            .filter((p) => !p.archived || memberIds.includes(p.id))
            .map((p) => {
              const on = memberIds.includes(p.id);
              return (
                <button
                  key={p.id}
                  type="button"
                  aria-pressed={on}
                  onClick={() =>
                    setMemberIds((ids) =>
                      on ? ids.filter((x) => x !== p.id) : [...ids, p.id],
                    )
                  }
                  className={cn(
                    "inline-flex items-center gap-1.5 rounded-full border py-1 pl-1 pr-2.5 text-xs font-medium transition-colors",
                    on
                      ? "border-transparent text-foreground"
                      : "border-border text-muted hover:bg-surface-2",
                  )}
                  style={on ? { backgroundColor: `${p.color}22` } : undefined}
                >
                  <Avatar
                    name={p.name}
                    color={p.color}
                    emoji={p.emoji}
                    size="sm"
                    className="h-5 w-5 text-[10px]"
                  />
                  {p.name}
                  {on && <Check className="h-3 w-3" />}
                </button>
              );
            })}
        </div>
      </div>

      {error && <p className="text-sm font-medium text-red-500">{error}</p>}

      <div className="flex gap-2">
        {group && (
          <Button
            variant="ghost"
            onClick={remove}
            disabled={busy}
            aria-label="Delete group"
            className="text-red-500 hover:bg-red-500/10 hover:text-red-500"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        )}
        <Button variant="secondary" className="flex-1" onClick={onDone}>
          Cancel
        </Button>
        <Button className="flex-1" onClick={save} disabled={busy}>
          Save
        </Button>
      </div>
    </div>
  );
}
