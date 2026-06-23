import { createElement } from "react";
import { habitIcon } from "@/lib/habit-icons";

/**
 * Renders a habit's icon by name. Using a stable module-scope component (and
 * createElement) keeps the dynamic lookup out of caller render bodies.
 */
export function HabitGlyph({
  name,
  className,
}: {
  name: string | null;
  className?: string;
}) {
  return createElement(habitIcon(name), { className });
}
