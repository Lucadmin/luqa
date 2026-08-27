# Sleep & Health Integration

Luqa stores sleep separately from tracked work/activity time in `sleep_entries`.
Reports aggregate sleep by wake-up day and show it alongside tracked time without
counting it toward tracked-time totals.

Scalar measurements (steps, heart rate, body metrics) land in `health_samples`.
Nothing writes to that table yet — see [Adding a metric](#adding-a-metric).

## Data model

| Table | Holds | Identity |
| --- | --- | --- |
| `sleep_entries` | Sleep sessions, with their stage timeline and derived quality metrics | `(userId, source, externalId)` |
| `health_samples` | One scalar or interval measurement per row | `(userId, source, metric, externalId)` |
| `health_sync_states` | Per-user, per-source, per-metric watermarks | `(userId, source, metric)` |

`HealthSource` is shared across all of them (`HEALTH_CONNECT`, `APPLE_HEALTH`,
`GOOGLE_HEALTH`, `MANUAL`), so a new metric never needs a new source enum.
`externalId` is the provider's record id, which makes every import idempotent:
replaying a batch upserts onto the same rows.

Two rules hold everywhere:

- **Manual override wins.** A row with `manualOverrideAt` set keeps its values;
  a provider refresh only updates provenance (`sourceApp`, `raw`, `lastSyncedAt`).
- **Deletes are soft.** `deletedAt` is set rather than the row being removed, so
  a provider that briefly stops reporting a record does not erase history.

### Sleep detail

Health Connect reports a stage timeline, so the server derives the numbers rather
than trusting client arithmetic. Every stage total is `null` when the provider
did not report that stage — which is not the same as reporting zero.

| Column | Meaning |
| --- | --- |
| `sleepMinutes` | Total asleep: light + deep + REM + unspecified asleep |
| `awakeMinutes` | Awake inside the session |
| `awakeInBedMinutes` / `outOfBedMinutes` | Tracked apart from `awakeMinutes`: lying awake and getting up say different things about a night |
| `lightMinutes` / `deepMinutes` / `remMinutes` | Stage totals |
| `unknownMinutes` | Staged time the provider could not classify |
| `inBedMinutes` | Wall-clock session length |
| `efficiencyPercent` | Asleep as a share of time in bed, 0–100 |
| `latencyMinutes` | Session start until the first asleep stage |
| `wasoMinutes` | Wake after sleep onset, before the final wake |
| `awakeningCount` | Distinct awake blocks after sleep onset; touching stages count once |
| `midpoint` | Midpoint of the asleep span, for chronotype drift |
| `isNap`, `notes`, `recordingMethod`, `deviceModel` | Session provenance |

The derivation lives in `src/lib/health/sleep-metrics.ts` and is unit-tested in
`tests/server/sleep-metrics.test.mjs`. It is deliberately free of database
imports so it can be tested as a pure function.

Time before the first sleep stage counts as latency, not WASO; time after the
last counts as being up for the day. Metrics that need the timeline return `null`
when a session arrives with only summary totals, rather than inventing numbers
from a duration.

## Android Health Connect (primary path)

Health Connect is an on-device API, so the phone reads it and pushes to the
server. Samsung Health, Fitbit, Oura and friends write into Health Connect, so
one integration covers all of them.

### Server

`POST /api/v1/health/sync` (mobile bearer token). Idempotent by record id.

```jsonc
{
  "source": "HEALTH_CONNECT",
  "sleep": {
    "entries": [
      {
        "externalId": "health-connect-record-id",
        "sourceApp": "Samsung Health",
        "startTime": "2026-08-26T21:45:00.000Z",
        "endTime": "2026-08-27T05:30:00.000Z",
        "isNap": false,
        "recordingMethod": "AUTOMATICALLY_RECORDED",
        "stages": [
          {
            "stage": "DEEP",
            "startTime": "2026-08-26T22:20:00.000Z",
            "endTime": "2026-08-26T23:05:00.000Z"
          }
        ]
      }
    ],
    "deletedExternalIds": [],
    // Only when the device re-read a full range. Authorizes the server to
    // soft-delete sessions inside it that the device no longer sees.
    "window": { "from": "...", "to": "..." }
  },
  "samples": [],
  "deletedSamples": []
}
```

`GET /api/v1/health/sync` returns the per-metric watermarks the server holds.

The client sends stages but **not** stage totals: the server derives every minute
count and quality metric, so there is one implementation of that arithmetic
rather than one per platform.

### Client

- `mobile/lib/features/health/data/health_connect_reader.dart` — reads the
  platform store and rebuilds sessions. The `health` plugin returns a session and
  each of its stages as separate points that all carry the parent record's id as
  `uuid`; grouping by `uuid` reassembles the session with its timeline.
- `mobile/lib/features/health/application/health_sync_controller.dart` — window
  selection, permission flow, push.
- `mobile/lib/features/health/data/health_sync_store.dart` — device-local
  watermarks. Lives on the phone because it describes what *this install* read;
  reinstalling correctly triggers a fresh backfill.

Sync windows: a first sync reaches back 30 days (Health Connect only guarantees
30 days without the extra read-history permission). Later syncs re-read the last
3 days, because trackers revise a night for a while after you wake up.

### Android configuration

Already applied in `mobile/android/`:

```xml
<uses-permission android:name="android.permission.health.READ_SLEEP" />
```

plus, all required by Health Connect:

- `<queries>` for `com.google.android.apps.healthdata` and the rationale intent,
  so the app can detect whether Health Connect is installed.
- An `androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE` intent filter on
  `MainActivity`, and a matching `ViewPermissionUsageActivity` activity-alias.
- `MainActivity` extends `FlutterFragmentActivity`, not `FlutterActivity`: the
  permission contract uses `registerForActivityResult`, which needs a
  `FragmentActivity` host on Android 14+.
- `minSdk = 26`.

Play Console reviews every health permission an app declares, so do not add
permissions speculatively — add them when a metric is actually switched on.

### iOS

Not wired up. Health Connect is Android-only; the tile reports the platform as
unsupported. The `health` package also covers HealthKit, so an iOS path means
adding the entitlement, `NSHealthShareUsageDescription`, and mapping sessions to
`HealthSource.APPLE_HEALTH` — the server already accepts that source.

## Adding a metric

1. Add the value to `HealthMetricType` in `prisma/schema.prisma` and to
   `healthMetricType` in `src/lib/validations.ts` (plus a migration).
2. Add it to `HealthMetricType` in `docs/api/openapi.v1.yaml`, then
   `npm run api:generate`.
3. Add a `HealthMetricDescriptor` to `enabledHealthMetrics` in
   `mobile/lib/features/health/domain/health_metric.dart`.
4. Declare the matching Health Connect permission in `AndroidManifest.xml`.

The reader, the push, and the sync bookkeeping are all driven off that
descriptor list, so no new pipeline is needed.

## Google Health API (retired)

Superseded by on-device Health Connect. The code and any existing connections
are kept — nothing is deleted, and previously imported sessions stay readable and
attributed to `GOOGLE_HEALTH` — but nothing calls the sync any more:

- `POST /api/health/google/sync` returns `410 Gone`.
- The webhook acknowledges notifications with `204` without syncing (a non-2xx
  would make Google retry forever).
- The OAuth callback no longer runs an initial sync.
- Settings shows the panel as **Retired**, offering only Disconnect.

`src/lib/google-health/` is marked `@deprecated` and still compiles, so the path
can be revived if Health Connect proves insufficient. `GOOGLE_HEALTH_CLIENT_ID`,
`GOOGLE_HEALTH_CLIENT_SECRET` and `GOOGLE_HEALTH_WEBHOOK_TOKEN` are no longer
read on any live path.

## Reference

- https://developer.android.com/health-and-fitness/health-connect/features/sleep-sessions
- https://developer.android.com/health-and-fitness/health-connect/sync-data
- https://developer.samsung.com/health/blog/en/accessing-samsung-health-data-through-health-connect
- https://pub.dev/packages/health

The old Google Fit REST API is not a target for new work.
