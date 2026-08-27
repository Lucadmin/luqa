"use client";

import { CalendarDays, Check, Moon, RefreshCw, Unlink, X } from "lucide-react";
import { useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { CategoriesPanel } from "@/components/settings/categories-panel";
import { PreferencesPanel, ProfilePanel } from "@/components/settings/preferences-panel";
import { AppPage, AppPageHeader } from "@/components/ui/app-page";
import { Button } from "@/components/ui/button";
import { apiSend } from "@/lib/client/fetcher";
import { useGoogleHealthStatus } from "@/lib/client/use-google-health-status";
import { useGoogleStatus } from "@/lib/client/use-google-status";

function GoogleConnectionPanel() {
  const { status, isLoading, mutate } = useGoogleStatus();
  const searchParams = useSearchParams();
  const [syncing, setSyncing] = useState(false);
  const [syncResult, setSyncResult] = useState<string | null>(null);
  const [disconnecting, setDisconnecting] = useState(false);

  // Toast-style feedback from the OAuth callback redirect.
  const oauthResult = searchParams.get("google");

  async function handleSync() {
    setSyncing(true);
    setSyncResult(null);
    try {
      const res = await apiSend<{ added: number; updated: number; deleted: number }>(
        "/api/google/sync",
        "POST",
      );
      setSyncResult(`Synced: +${res.added} added, ${res.updated} updated, ${res.deleted} removed`);
      await mutate();
    } catch {
      setSyncResult("Sync failed. Please try again.");
    } finally {
      setSyncing(false);
    }
  }

  async function handleDisconnect() {
    setDisconnecting(true);
    try {
      await apiSend("/api/google/disconnect", "DELETE");
      await mutate();
    } finally {
      setDisconnecting(false);
    }
  }

  if (isLoading) {
    return <div className="h-20 animate-pulse rounded-xl bg-surface-2" />;
  }

  return (
    <div className="flex flex-col gap-4">
      {oauthResult === "connected" && (
        <div className="flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700 dark:border-green-900 dark:bg-green-950/30 dark:text-green-400">
          <Check className="h-4 w-4 shrink-0" />
          Google Calendar connected successfully.
        </div>
      )}
      {(oauthResult === "error" || oauthResult === "denied") && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-400">
          <X className="h-4 w-4 shrink-0" />
          {oauthResult === "denied"
            ? "Google Calendar connection was declined."
            : "Could not connect to Google Calendar. Please try again."}
        </div>
      )}

      <div className="rounded-2xl border border-border bg-surface p-5">
        <div className="flex flex-col gap-4">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-surface-2">
              <CalendarDays className="h-5 w-5 text-muted" />
            </div>
            <div className="min-w-0 flex-1">
              <h3 className="text-sm font-semibold">Google Calendar</h3>
              {status.connected ? (
                <div className="mt-0.5 flex flex-col gap-0.5">
                  <p className="truncate text-sm text-muted">
                    Connected as{" "}
                    <span className="font-medium text-foreground">
                      {status.googleEmail}
                    </span>
                  </p>
                  <p className="text-xs text-faint">
                    {status.webhookActive
                      ? "Live sync active — changes in Google Calendar appear here automatically."
                      : "Sync is manual. Click Sync now to pull recent changes."}
                  </p>
                  {status.lastSynced && (
                    <p className="text-xs text-faint">
                      Last synced:{" "}
                      {new Date(status.lastSynced).toLocaleString(undefined, {
                        year: "numeric",
                        month: "short",
                        day: "numeric",
                        hour: "2-digit",
                        minute: "2-digit",
                        hour12: false,
                      })}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-0.5 text-sm text-muted">
                  Connect to sync your tracked time to Google Calendar — and
                  import events you add there back into Luqa.
                </p>
              )}
            </div>
          </div>

          {status.connected ? (
            <div className="flex items-center gap-2">
              <Button
                variant="secondary"
                size="sm"
                onClick={handleSync}
                disabled={syncing}
              >
                <RefreshCw className={`h-3.5 w-3.5 ${syncing ? "animate-spin" : ""}`} />
                {syncing ? "Syncing…" : "Sync now"}
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={handleDisconnect}
                disabled={disconnecting}
                className="text-muted hover:text-red-500"
              >
                <Unlink className="h-3.5 w-3.5" />
                Disconnect
              </Button>
            </div>
          ) : (
            <div>
              <a href="/api/google/connect">
                <Button size="sm">Connect</Button>
              </a>
            </div>
          )}
        </div>

        {syncResult && (
          <p className="mt-3 text-xs text-muted">{syncResult}</p>
        )}
      </div>
    </div>
  );
}

function GoogleHealthPanel() {
  const { status, isLoading, mutate } = useGoogleHealthStatus();
  const searchParams = useSearchParams();
  const [disconnecting, setDisconnecting] = useState(false);

  const oauthResult = searchParams.get("health");

  async function handleDisconnect() {
    setDisconnecting(true);
    try {
      await apiSend("/api/health/google/disconnect", "DELETE");
      await mutate();
    } finally {
      setDisconnecting(false);
    }
  }

  if (isLoading) {
    return <div className="h-20 animate-pulse rounded-xl bg-surface-2" />;
  }

  return (
    <div className="flex flex-col gap-4">
      {oauthResult === "connected" && (
        <div className="flex items-center gap-2 rounded-xl border border-green-200 bg-green-50 px-4 py-3 text-sm text-green-700 dark:border-green-900 dark:bg-green-950/30 dark:text-green-400">
          <Check className="h-4 w-4 shrink-0" />
          Google Health connected successfully.
        </div>
      )}
      {(oauthResult === "error" || oauthResult === "denied") && (
        <div className="flex items-center gap-2 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/30 dark:text-red-400">
          <X className="h-4 w-4 shrink-0" />
          {oauthResult === "denied"
            ? "Google Health connection was declined."
            : "Could not connect to Google Health. Check API access and try again."}
        </div>
      )}

      <div className="rounded-2xl border border-border bg-surface p-5">
        <div className="flex flex-col gap-4">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-surface-2">
              <Moon className="h-5 w-5 text-muted" />
            </div>
            <div className="min-w-0 flex-1">
              <div className="flex items-center gap-2">
                <h3 className="text-sm font-semibold">Google Health</h3>
                <span className="rounded-md bg-surface-2 px-1.5 py-0.5 text-[10px] font-medium uppercase tracking-wide text-faint">
                  Retired
                </span>
              </div>
              {status.connected ? (
                <div className="mt-0.5 flex flex-col gap-0.5">
                  <p className="truncate text-sm text-muted">
                    Connected as{" "}
                    <span className="font-medium text-foreground">
                      {status.googleEmail ?? status.healthUserId ?? "Google Health"}
                    </span>
                  </p>
                  <p className="text-xs text-faint">
                    No longer syncing. Sleep now comes from Health Connect on your
                    phone; sessions imported here previously are kept.
                  </p>
                  {status.lastSynced && (
                    <p className="text-xs text-faint">
                      Last synced:{" "}
                      {new Date(status.lastSynced).toLocaleString(undefined, {
                        year: "numeric",
                        month: "short",
                        day: "numeric",
                        hour: "2-digit",
                        minute: "2-digit",
                        hour12: false,
                      })}
                    </p>
                  )}
                </div>
              ) : (
                <p className="mt-0.5 text-sm text-muted">
                  Retired. Sleep is imported by the Luqa mobile app from Android
                  Health Connect, which also carries Samsung Health data.
                </p>
              )}
            </div>
          </div>

          {status.connected && (
            <Button
              variant="ghost"
              size="sm"
              onClick={handleDisconnect}
              disabled={disconnecting}
              className="self-start text-muted hover:text-red-500"
            >
              <Unlink className="h-3.5 w-3.5" />
              Disconnect
            </Button>
          )}
        </div>
      </div>
    </div>
  );
}

function Section({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="flex flex-col gap-3">
      <h2 className="text-sm font-medium uppercase tracking-wide text-faint">
        {title}
      </h2>
      {children}
    </section>
  );
}

export function SettingsView() {
  return (
    <AppPage className="py-6 md:py-8">
      <AppPageHeader title="Settings" />

      <div className="mt-6 flex flex-col gap-8">
        <Section title="Profile">
          <ProfilePanel />
        </Section>

        <Section title="Preferences">
          <PreferencesPanel />
        </Section>

        <Section title="Categories">
          <CategoriesPanel />
        </Section>

        <Section title="Integrations">
          <Suspense fallback={<div className="h-20 animate-pulse rounded-xl bg-surface-2" />}>
            <div className="flex flex-col gap-4">
              <GoogleConnectionPanel />
              <GoogleHealthPanel />
            </div>
          </Suspense>
        </Section>
      </div>
    </AppPage>
  );
}
