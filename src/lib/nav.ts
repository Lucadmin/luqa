import {
  BarChart3,
  Clock,
  Dumbbell,
  Grid3x3,
  Settings,
  Target,
  Wallet,
} from "lucide-react";

export const NAV_ITEMS = [
  { href: "/", label: "Day", icon: Clock },
  { href: "/habits", label: "Habits", icon: Target },
  { href: "/gym", label: "Gym", icon: Dumbbell },
  { href: "/money", label: "Money", icon: Wallet },
  { href: "/reports", label: "Reports", icon: BarChart3 },
  { href: "/life", label: "Life", icon: Grid3x3 },
  { href: "/settings", label: "Settings", icon: Settings },
] as const;
