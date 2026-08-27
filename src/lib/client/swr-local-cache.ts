"use client";

import type { Cache } from "swr";

const STORAGE_KEY = "luqa:swr-cache:v1";
const SAVE_INTERVAL_MS = 30_000;

type CacheValue = ReturnType<Cache["get"]>;

function readPersisted(): Map<string, CacheValue> {
  if (typeof window === "undefined") return new Map();
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw
      ? new Map<string, CacheValue>(JSON.parse(raw) as [string, CacheValue][])
      : new Map();
  } catch {
    return new Map();
  }
}

function writePersisted(map: Map<string, CacheValue>) {
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
  let dirty = false;

  const cache: Cache = {
    get: (key) => map.get(key),
    set: (key, value) => {
      dirty = true;
      map.set(key, value);
    },
    delete: (key) => {
      dirty = true;
      map.delete(key);
    },
    keys: () => map.keys(),
  };

  if (typeof window !== "undefined") {
    const save = () => {
      if (!dirty) return;
      writePersisted(map);
      dirty = false;
    };
    const saveWhenIdle = () => {
      if (!dirty) return;
      const idleWindow = window as Window & {
        requestIdleCallback?: Window["requestIdleCallback"];
      };
      if (typeof idleWindow.requestIdleCallback === "function") {
        idleWindow.requestIdleCallback(save, { timeout: 2_000 });
      } else {
        setTimeout(save, 0);
      }
    };

    setInterval(saveWhenIdle, SAVE_INTERVAL_MS);
    window.addEventListener("pagehide", save);
    window.addEventListener("beforeunload", save);
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "hidden") save();
    });
  }

  return cache;
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
