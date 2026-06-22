"use client";

import dynamic from "next/dynamic";

// dynamic ssr:false must live in a client component (not a server component).
// This wrapper exists solely to carry that constraint while keeping page.tsx
// as a server component so it can export metadata.
const DayView = dynamic(
  () => import("@/components/timeline/day-view").then((m) => m.DayView),
  { ssr: false },
);

export function DayViewWrapper() {
  return <DayView />;
}
