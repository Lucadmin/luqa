"use client";

import { CalendarDays, Check, RefreshCw, Unlink, X } from "lucide-react";
import { useSearchParams } from "next/navigation";
import { Suspense, useState } from "react";
import { CategoriesPanel } from "@/components/settings/categories-panel";
import { PreferencesPanel, ProfilePanel } from "@/components/settings/preferences-panel";
import { Button } from "@/components/ui/button";
import { apiSend } from "@/lib/client/fetcher";
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
        <div className="flex items-start justify-between gap-4">
          <div className="flex items-start gap-3">
            <div className="mt-0.5 grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-surface-2">
              <CalendarDays className="h-5 w-5 text-muted" />
            </div>
            <div>
              <h3 className="text-sm font-semibold">Google Calendar</h3>
              {status.connected ? (
                <div className="mt-0.5 flex flex-col gap-0.5">
                  <p className="text-sm text-muted">
                    Connected as{" "}
                    <span className="font-medium text-foreground">
                      {status.googleEmail}
                    </span>
                  </p>
                  <p className="text-xs text-faint">
                    {status.webhookActive
                      ? "Live sync active — changes in Google Calendar appear here automatically."
                      : "Sync is manual for now. Click “Sync now” to pull recent changes."}
                  </p>
                  {status.lastSynced && (
                    <p className="text-xs text-faint">
                      Last synced:{" "}
                      {new Date(status.lastSynced).toLocaleString(undefined, {
                        dateStyle: "medium",
                        timeStyle: "short",
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
            <div className="flex shrink-0 items-center gap-2">
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
            <a href="/api/google/connect">
              <Button size="sm">Connect</Button>
            </a>
          )}
        </div>

        {syncResult && (
          <p className="mt-3 text-xs text-muted">{syncResult}</p>
        )}
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
    <div className="mx-auto w-full max-w-2xl px-4 py-6 md:px-8 md:py-8">
      <h1 className="text-xl font-semibold tracking-tight">Settings</h1>

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
            <GoogleConnectionPanel />
          </Suspense>
        </Section>
      </div>
    </div>
  );
}
