import { cn } from "@/lib/cn";

/** Initials from a name: "Max" → "M", "Lena Weber" → "LW". */
function initials(name: string): string {
  const parts = name.trim().split(/\s+/).slice(0, 2);
  return parts.map((p) => p[0]?.toUpperCase() ?? "").join("") || "?";
}

const SIZES = {
  sm: "h-7 w-7 text-[11px]",
  md: "h-9 w-9 text-xs",
  lg: "h-12 w-12 text-base",
} as const;

/** A person or group, as a tinted disc with their emoji or initials. */
export function Avatar({
  name,
  color,
  emoji,
  size = "md",
  className,
}: {
  name: string;
  color: string;
  emoji?: string | null;
  size?: keyof typeof SIZES;
  className?: string;
}) {
  return (
    <span
      aria-hidden
      style={{ backgroundColor: `${color}22`, color }}
      className={cn(
        "grid shrink-0 place-items-center rounded-full font-semibold",
        SIZES[size],
        className,
      )}
    >
      {emoji || initials(name)}
    </span>
  );
}
