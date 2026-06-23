import { BarChart3, CalendarDays, Clock, Settings, Target } from "lucide-react";

export const NAV_ITEMS = [
  { href: "/", label: "Day", icon: Clock },
  { href: "/week", label: "Week", icon: CalendarDays },
  { href: "/habits", label: "Habits", icon: Target },
  { href: "/reports", label: "Reports", icon: BarChart3 },
  { href: "/settings", label: "Settings", icon: Settings },
] as const;
