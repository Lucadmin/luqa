"use client";

import { LogOut } from "lucide-react";
import { signOut } from "next-auth/react";
import { clearPersistedSwrCache } from "@/lib/client/swr-local-cache";
import { cn } from "@/lib/cn";

export function SignOutButton({
  className,
  withLabel = true,
}: {
  className?: string;
  withLabel?: boolean;
}) {
  return (
    <button
      type="button"
      onClick={() => {
        clearPersistedSwrCache();
        signOut({ callbackUrl: "/login" });
      }}
      className={cn(
        "inline-flex items-center gap-2 text-sm text-muted transition-colors hover:text-foreground",
        className,
      )}
    >
      <LogOut className="h-4 w-4" />
      {withLabel && "Sign out"}
    </button>
  );
}
