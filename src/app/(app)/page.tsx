import { Clock } from "lucide-react";

export const metadata = { title: "Day · Luqa" };

export default function DayPage() {
  const today = new Date().toLocaleDateString(undefined, {
    weekday: "long",
    month: "long",
    day: "numeric",
  });

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6 md:px-8 md:py-8">
      <div className="flex items-baseline justify-between">
        <h1 className="text-xl font-semibold tracking-tight">Today</h1>
        <span className="text-sm text-muted">{today}</span>
      </div>

      <div className="mt-10 flex flex-col items-center justify-center gap-3 rounded-2xl border border-dashed border-border py-20 text-center">
        <div className="grid h-12 w-12 place-items-center rounded-full bg-surface-2 text-faint">
          <Clock className="h-5 w-5" />
        </div>
        <p className="text-sm font-medium">The timeline lands here next</p>
        <p className="max-w-xs text-sm text-muted">
          The day view, live timer, and gap-recovery flow are coming in the next
          build step.
        </p>
      </div>
    </div>
  );
}
