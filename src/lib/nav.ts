import { BarChart3, Clock, Grid3x3, Settings, Target, Wallet } from "lucide-react";

export const NAV_ITEMS = [
  { href: "/", label: "Day", icon: Clock },
  { href: "/habits", label: "Habits", icon: Target },
  { href: "/money", label: "Money", icon: Wallet },
  { href: "/reports", label: "Reports", icon: BarChart3 },
  { href: "/life", label: "Life", icon: Grid3x3 },
  { href: "/settings", label: "Settings", icon: Settings },
] as const;
