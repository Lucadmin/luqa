import { cn } from "@/lib/cn";

const WIDTHS = {
  compact: "max-w-2xl",
  wide: "max-w-4xl",
} as const;

export function AppPage({
  children,
  width = "compact",
  className,
}: {
  children: React.ReactNode;
  width?: keyof typeof WIDTHS;
  className?: string;
}) {
  return (
    <div
      className={cn(
        "mx-auto w-full px-4 py-5 md:px-8 md:py-7",
        WIDTHS[width],
        className,
      )}
    >
      {children}
    </div>
  );
}

export function AppPageHeader({
  title,
  actions,
}: {
  title: string;
  actions?: React.ReactNode;
}) {
  return (
    <header className="flex items-center justify-between gap-3">
      <h1 className="text-xl font-semibold tracking-tight">{title}</h1>
      {actions}
    </header>
  );
}
