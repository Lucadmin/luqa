"use client";

import { useEffect, useRef } from "react";

export function InfiniteListFooter({
  hasMore,
  isLoading,
  onLoadMore,
  label,
}: {
  hasMore: boolean;
  isLoading: boolean;
  onLoadMore: () => void | Promise<unknown>;
  label: string;
}) {
  const sentinelRef = useRef<HTMLDivElement>(null);
  const loadRef = useRef(onLoadMore);

  useEffect(() => {
    loadRef.current = onLoadMore;
  }, [onLoadMore]);

  useEffect(() => {
    const target = sentinelRef.current;
    if (!target || !hasMore || isLoading) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (!entry?.isIntersecting) return;
        observer.disconnect();
        void loadRef.current();
      },
      { rootMargin: "300px 0px" },
    );

    observer.observe(target);
    return () => observer.disconnect();
  }, [hasMore, isLoading]);

  if (!hasMore) return null;

  return (
    <div ref={sentinelRef} className="flex justify-center py-3">
      <button
        type="button"
        onClick={() => void onLoadMore()}
        disabled={isLoading}
        className="rounded-full px-3 py-1.5 text-xs font-medium text-muted transition-colors hover:bg-surface-2 hover:text-foreground disabled:cursor-wait disabled:opacity-60"
      >
        {isLoading ? "Loading…" : label}
      </button>
    </div>
  );
}
