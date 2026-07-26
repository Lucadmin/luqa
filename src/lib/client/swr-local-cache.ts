"use client";

import type { Cache } from "swr";

const STORAGE_KEY = "luqa:swr-cache:v1";
const SAVE_INTERVAL_MS = 30_000;

function readPersisted(): Map<string, unknown> {
  if (typeof window === "undefined") return new Map();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? new Map(JSON.parse(raw)) : new Map();
  } catch {
    return new Map();
  }
}

function writePersisted(map: Map<string, unknown>) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(Array.from(map.entries())));
  } catch {
    // Quota exceeded or storage unavailable (e.g. private browsing) — the
    // in-memory cache keeps working for this session, just don't persist it.
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      /* ignore */
    }
  }
}

/**
 * SWR cache provider backed by localStorage. Whatever was on screen last
 * session is available the instant a route mounts (shown as stale while SWR
 * revalidates in the background), instead of every navigation and every cold
 * PWA launch starting from a blank/loading state.
 */
export function localStorageCacheProvider(): Cache {
  const map = readPersisted();

  if (typeof window !== "undefined") {
    const save = () => writePersisted(map);
    setInterval(save, SAVE_INTERVAL_MS);
    window.addEventListener("pagehide", save);
    window.addEventListener("beforeunload", save);
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "hidden") save();
    });
  }

  return map as unknown as Cache;
}

/**
 * Wipe the persisted cache. Call on sign-out so the next account on a shared
 * device doesn't briefly see the previous user's cached data.
 */
export function clearPersistedSwrCache() {
  if (typeof window === "undefined") return;
  try {
    localStorage.removeItem(STORAGE_KEY);
  } catch {
    /* ignore */
  }
}
