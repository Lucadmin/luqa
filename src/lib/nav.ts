import { BarChart3, CalendarDays, Clock } from "lucide-react";

export const NAV_ITEMS = [
  { href: "/", label: "Day", icon: Clock },
  { href: "/week", label: "Week", icon: CalendarDays },
  { href: "/reports", label: "Reports", icon: BarChart3 },
] as const;
