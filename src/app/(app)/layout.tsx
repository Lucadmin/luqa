import { redirect } from "next/navigation";
import { auth } from "@/auth";
import { MobileTabBar, Sidebar } from "@/components/nav";
import { ThemeToggle } from "@/components/theme-toggle";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const session = await auth();
  if (!session?.user) redirect("/login");

  const userLabel = session.user.name || session.user.email || "Account";

  return (
    <div className="flex h-dvh overflow-hidden">
      <Sidebar userLabel={userLabel} />

      <div className="flex min-w-0 flex-1 flex-col">
        {/* Mobile top bar */}
        <header className="flex shrink-0 items-center justify-between border-b border-border bg-surface px-4 py-3 md:hidden">
          <span className="text-base font-semibold tracking-tight">luqa</span>
          <ThemeToggle />
        </header>

        {/* pb leaves room for the mobile tab bar */}
        <main className="flex-1 overflow-y-auto pb-20 md:pb-0">{children}</main>
      </div>

      <MobileTabBar />
    </div>
  );
}
