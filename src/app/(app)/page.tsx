import dynamic from "next/dynamic";

// DayView uses local timezone for "now" and day boundaries — disable SSR so
// it always runs in the client's timezone, never the server's UTC.
const DayView = dynamic(
  () => import("@/components/timeline/day-view").then((m) => m.DayView),
  { ssr: false },
);

export const metadata = { title: "Day · Luqa" };

export default function DayPage() {
  return <DayView />;
}
