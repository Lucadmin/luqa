"use client";

import { useEffect, useState } from "react";

/** Value that settles `delay` ms after the last change. */
export function useDebounced<T>(value: T, delay = 200): T {
  const [settled, setSettled] = useState(value);

  useEffect(() => {
    const id = setTimeout(() => setSettled(value), delay);
    return () => clearTimeout(id);
  }, [value, delay]);

  return settled;
}
