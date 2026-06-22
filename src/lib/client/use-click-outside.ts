"use client";

import { useEffect, type RefObject } from "react";

export function useClickOutside(
  ref: RefObject<HTMLElement | null>,
  onOutside: () => void,
  enabled = true,
) {
  useEffect(() => {
    if (!enabled) return;
    function handle(e: PointerEvent) {
      const el = ref.current;
      if (el && !el.contains(e.target as Node)) onOutside();
    }
    document.addEventListener("pointerdown", handle);
    return () => document.removeEventListener("pointerdown", handle);
  }, [ref, onOutside, enabled]);
}
