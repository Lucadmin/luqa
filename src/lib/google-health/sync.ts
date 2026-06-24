import type { SleepSource } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import { googleHealthClientForUser, googleHealthFetch } from "@/lib/google-health/oauth";
import { importSleepEntries, markMissingSleepEntriesDeleted } from "@/lib/sleep";
import type { ImportSleepInput } from "@/lib/validations";

interface GoogleHealthIdentity {
  healthUserId?: string;
  legacyUserId?: string;
}

interface GoogleHealthSleepInterval {
  startTime: string;
  startUtcOffset?: string;
  endTime: string;
  endUtcOffset?: string;
}

interface GoogleHealthSleepStage {
  startTime: string;
  startUtcOffset?: string;
  endTime: string;
  endUtcOffset?: string;
  type: string;
}

interface GoogleHealthStageSummary {
  type: string;
  minutes?: string;
  count?: string;
}

interface GoogleHealthSleep {
  interval?: GoogleHealthSleepInterval;
  type?: string;
  stages?: GoogleHealthSleepStage[];
  metadata?: { externalId?: string; nap?: boolean; manuallyEdited?: boolean };
  summary?: {
    stagesSummary?: GoogleHealthStageSummary[];
    minutesAsleep?: string;
    minutesAwake?: string;
    minutesInSleepPeriod?: string;
  };
  createTime?: string;
  updateTime?: string;
}

interface GoogleHealthSleepPoint {
  name?: string;
  dataPointName?: string;
  sleep?: GoogleHealthSleep;
  dataSource?: {
    platform?: string;
    application?: { name?: string; packageName?: string };
    device?: { manufacturer?: string; displayName?: string };
  };
}

interface GoogleHealthSleepResponse {
  dataPoints?: GoogleHealthSleepPoint[];
  nextPageToken?: string;
}

type GoogleHealthSleepReadMode = "list" | "reconcile";

function intMinutes(value: string | number | undefined): number | null {
  if (value === undefined) return null;
  const parsed = typeof value === "number" ? value : Number.parseInt(value, 10);
  return Number.isFinite(parsed) ? parsed : null;
}

function stageSummaryMinutes(
  summaries: GoogleHealthStageSummary[] | undefined,
  names: Set<string>,
): number | null {
  const total = (summaries ?? []).reduce((sum, summary) => {
    const type = summary.type?.toUpperCase();
    if (!names.has(type)) return sum;
    return sum + (intMinutes(summary.minutes) ?? 0);
  }, 0);
  return total > 0 ? total : null;
}

function sourceAppFor(point: GoogleHealthSleepPoint): string | null {
  const source = point.dataSource;
  if (!source) return null;
  return (
    source.application?.name ??
    source.application?.packageName ??
    source.device?.displayName ??
    source.platform ??
    null
  );
}

function sleepPointExternalId(point: GoogleHealthSleepPoint, sleep: GoogleHealthSleep): string {
  return (
    point.dataPointName ??
    point.name ??
    sleep.metadata?.externalId ??
    `google-health:${sleep.interval?.startTime ?? ""}:${sleep.interval?.endTime ?? ""}`
  );
}

function toImportEntry(point: GoogleHealthSleepPoint): ImportSleepInput["entries"][number] | null {
  const sleep = point.sleep;
  const interval = sleep?.interval;
  if (!sleep || !interval?.startTime || !interval.endTime) return null;

  const summaries = sleep.summary?.stagesSummary;
  const stages = (sleep.stages ?? []).map((stage) => ({
    stage: stage.type,
    startTime: stage.startTime,
    endTime: stage.endTime,
  }));

  return {
    externalId: sleepPointExternalId(point, sleep),
    title: sleep.metadata?.nap ? "Nap" : "Sleep",
    sourceApp: sourceAppFor(point),
    startTime: interval.startTime,
    endTime: interval.endTime,
    startZoneOffset: interval.startUtcOffset ?? null,
    endZoneOffset: interval.endUtcOffset ?? null,
    sleepMinutes: intMinutes(sleep.summary?.minutesAsleep),
    awakeMinutes: intMinutes(sleep.summary?.minutesAwake),
    lightMinutes: stageSummaryMinutes(summaries, new Set(["LIGHT"])),
    deepMinutes: stageSummaryMinutes(summaries, new Set(["DEEP"])),
    remMinutes: stageSummaryMinutes(summaries, new Set(["REM"])),
    stages,
    raw: point,
  };
}

function sessionKey(entry: ImportSleepInput["entries"][number]): string {
  return `${entry.startTime}|${entry.endTime}`;
}

function latestEnd(entries: ImportSleepInput["entries"]): string | null {
  let latest: string | null = null;
  for (const entry of entries) {
    if (!latest || Date.parse(entry.endTime) > Date.parse(latest)) {
      latest = entry.endTime;
    }
  }
  return latest;
}

async function fetchSleepEntries({
  accessToken,
  filter,
  mode,
}: {
  accessToken: string;
  filter: string;
  mode: GoogleHealthSleepReadMode;
}): Promise<ImportSleepInput["entries"]> {
  const entries: ImportSleepInput["entries"] = [];
  let pageToken: string | undefined;
  let pageCount = 0;

  do {
    const params = new URLSearchParams({
      filter,
      pageSize: "25",
    });
    if (mode === "reconcile") {
      params.set("dataSourceFamily", "users/me/dataSourceFamilies/all-sources");
    }
    if (pageToken) params.set("pageToken", pageToken);

    const suffix = mode === "reconcile" ? ":reconcile" : "";
    const response = await googleHealthFetch<GoogleHealthSleepResponse>(
      accessToken,
      `/users/me/dataTypes/sleep/dataPoints${suffix}?${params.toString()}`,
    );

    for (const point of response.dataPoints ?? []) {
      const entry = toImportEntry(point);
      if (entry) entries.push(entry);
    }

    pageToken = response.nextPageToken || undefined;
    pageCount++;
  } while (pageToken && pageCount < 80);

  return entries;
}

function mergeSleepEntries(
  rawEntries: ImportSleepInput["entries"],
  reconciledEntries: ImportSleepInput["entries"],
): ImportSleepInput["entries"] {
  const byExternalId = new Map<string, ImportSleepInput["entries"][number]>();
  const seenSessions = new Set<string>();

  // Prefer raw list results. Reconciled sleep can lag/omit recent raw sessions,
  // while raw points keep the source/stage payload we need for sleep analysis.
  for (const entry of rawEntries) {
    if (!entry.externalId) continue;
    byExternalId.set(entry.externalId, entry);
    seenSessions.add(sessionKey(entry));
  }

  for (const entry of reconciledEntries) {
    if (!entry.externalId || seenSessions.has(sessionKey(entry))) continue;
    byExternalId.set(entry.externalId, entry);
    seenSessions.add(sessionKey(entry));
  }

  return [...byExternalId.values()];
}

export async function fetchGoogleHealthIdentity(accessToken: string) {
  return googleHealthFetch<GoogleHealthIdentity>(accessToken, "/users/me/identity");
}

export async function syncGoogleHealthSleep(
  userId: string,
  options?: { from?: Date; to?: Date },
): Promise<{
  imported: number;
  deleted: number;
  from: string;
  to: string;
  raw: number;
  reconciled: number;
  latestEnd: string | null;
}> {
  const result = await googleHealthClientForUser(userId);
  if (!result) {
    return {
      imported: 0,
      deleted: 0,
      from: "",
      to: "",
      raw: 0,
      reconciled: 0,
      latestEnd: null,
    };
  }

  const from = options?.from ?? new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  const to = options?.to ?? new Date(Date.now() + 24 * 60 * 60 * 1000);
  const filter =
    `sleep.interval.end_time >= "${from.toISOString()}" ` +
    `AND sleep.interval.end_time < "${to.toISOString()}"`;

  const [rawEntries, reconciledEntries] = await Promise.all([
    fetchSleepEntries({
      accessToken: result.accessToken,
      filter,
      mode: "list",
    }),
    fetchSleepEntries({
      accessToken: result.accessToken,
      filter,
      mode: "reconcile",
    }),
  ]);
  const entries = mergeSleepEntries(rawEntries, reconciledEntries);

  const imported = await importSleepEntries(userId, {
    source: "GOOGLE_HEALTH",
    entries,
  });
  const deleted = await markMissingSleepEntriesDeleted({
    userId,
    source: "GOOGLE_HEALTH" as SleepSource,
    from,
    to,
    externalIds: entries.map((entry) => entry.externalId).filter(Boolean) as string[],
  });

  await db.googleHealthConnection.update({
    where: { userId },
    data: { lastSyncedAt: new Date() },
  });

  return {
    imported: imported.upserted,
    deleted,
    from: from.toISOString(),
    to: to.toISOString(),
    raw: rawEntries.length,
    reconciled: reconciledEntries.length,
    latestEnd: latestEnd(entries),
  };
}
