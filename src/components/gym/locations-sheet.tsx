"use client";

import { Check, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Sheet } from "@/components/ui/sheet";
import {
  createLocation,
  deleteLocation,
  updateLocation,
} from "@/lib/client/use-gym";
import type { GymLocationDTO } from "@/lib/types";

const SWATCHES = [
  "#6366f1",
  "#10b981",
  "#f59e0b",
  "#ef4444",
  "#ec4899",
  "#06b6d4",
  "#8b5cf6",
  "#84cc16",
];

/**
 * The gyms, as short code plus full name — matching how they get written down
 * in the moment ("STR") and how they need to read back later.
 */
export function LocationsSheet({
  open,
  onClose,
  locations,
}: {
  open: boolean;
  onClose: () => void;
  locations: GymLocationDTO[];
}) {
  const [code, setCode] = useState("");
  const [name, setName] = useState("");
  const [color, setColor] = useState(SWATCHES[0]);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit() {
    const trimmedCode = code.trim();
    if (!trimmedCode) return;

    setBusy(true);
    setError(null);
    try {
      if (editingId) {
        await updateLocation(editingId, {
          code: trimmedCode,
          name: name.trim() || trimmedCode,
          color,
        });
      } else {
        await createLocation({
          code: trimmedCode,
          // A gym with no long name yet is still perfectly usable.
          name: name.trim() || trimmedCode,
          color,
        });
      }
      setCode("");
      setName("");
      setEditingId(null);
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not save");
    } finally {
      setBusy(false);
    }
  }

  function edit(location: GymLocationDTO) {
    setEditingId(location.id);
    setCode(location.code);
    setName(location.name);
    setColor(location.color);
  }

  async function remove(id: string) {
    setBusy(true);
    try {
      await deleteLocation(id);
      if (editingId === id) {
        setEditingId(null);
        setCode("");
        setName("");
      }
    } catch (e) {
      setError(e instanceof Error ? e.message : "Could not remove");
    } finally {
      setBusy(false);
    }
  }

  return (
    <Sheet open={open} onClose={onClose} title="Gyms">
      <div className="flex flex-col gap-4">
        {error && <p className="text-sm text-red-500">{error}</p>}

        <div className="flex flex-col gap-2">
          <div className="flex gap-2">
            <Input
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="STR"
              maxLength={12}
              aria-label="Short code"
              className="w-24 uppercase"
            />
            <Input
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="What it stands for"
              aria-label="Full name"
              onKeyDown={(e) => {
                if (e.key === "Enter") submit();
              }}
            />
          </div>

          <div className="flex items-center gap-1.5">
            {SWATCHES.map((swatch) => (
              <button
                key={swatch}
                type="button"
                onClick={() => setColor(swatch)}
                aria-label={`Colour ${swatch}`}
                className="grid h-6 w-6 place-items-center rounded-full"
                style={{ backgroundColor: swatch }}
              >
                {color === swatch && <Check className="h-3.5 w-3.5 text-white" />}
              </button>
            ))}
            <Button
              size="sm"
              onClick={submit}
              disabled={busy || !code.trim()}
              aria-label={editingId ? undefined : "Add gym"}
              className="ml-auto"
            >
              {editingId ? "Save" : <Plus className="h-4 w-4" />}
            </Button>
          </div>
        </div>

        {locations.length > 0 && (
          <ul className="divide-y divide-border">
            {locations.map((location) => (
              <li key={location.id} className="flex items-center gap-2.5 py-2">
                <span
                  className="h-6 w-6 shrink-0 rounded-full"
                  style={{ backgroundColor: location.color }}
                  aria-hidden
                />
                <button
                  type="button"
                  onClick={() => edit(location)}
                  className="min-w-0 flex-1 text-left"
                >
                  <p className="truncate text-sm font-medium">
                    {location.code}
                    {location.archived && (
                      <span className="ml-1.5 text-xs font-normal text-faint">
                        archived
                      </span>
                    )}
                  </p>
                  {location.name !== location.code && (
                    <p className="truncate text-xs text-faint">{location.name}</p>
                  )}
                </button>
                <button
                  type="button"
                  onClick={() => remove(location.id)}
                  aria-label={`Remove ${location.code}`}
                  disabled={busy}
                  className="grid h-8 w-8 place-items-center rounded-lg text-faint transition-colors hover:bg-surface-2 hover:text-red-500"
                >
                  <Trash2 className="h-3.5 w-3.5" />
                </button>
              </li>
            ))}
          </ul>
        )}

        <p className="text-xs text-faint">
          Gyms with sessions behind them are archived rather than deleted, so old
          entries keep saying where they happened.
        </p>
      </div>
    </Sheet>
  );
}
