# Sleep Integration

Luqa stores sleep separately from tracked work/activity time in `sleep_entries`.
Reports aggregate sleep by wake-up day and show it alongside tracked time without
counting it toward tracked-time totals.

## Supported import paths

### Google Health API

The app includes server-side OAuth routes for the Google Health API:

- `GET /api/health/google/connect`
- `GET /api/health/google/callback`
- `POST /api/health/google/sync`
- `DELETE /api/health/google/disconnect`
- `POST /api/health/google/webhook`

Required scope:

```text
https://www.googleapis.com/auth/googlehealth.sleep.readonly
```

The sync code calls the Google Health `sleep` data type reconcile endpoint and
filters by `sleep.interval.end_time`, so sessions are attributed by wake time.

Environment variables:

```text
GOOGLE_HEALTH_CLIENT_ID=...
GOOGLE_HEALTH_CLIENT_SECRET=...
APP_URL=https://your-domain.example
GOOGLE_HEALTH_WEBHOOK_TOKEN=...
```

If the health-specific client variables are omitted, the app falls back to
`GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET`.

Google Cloud setup still needs to be done outside the repo:

- Enable/request Google Health API access for the project.
- Add `/api/health/google/callback` as an OAuth redirect URI.
- Configure a Google Health webhook subscriber pointing at
  `/api/health/google/webhook?token=<GOOGLE_HEALTH_WEBHOOK_TOKEN>` for automatic
  change notifications when a token is configured.

Reference docs:

- https://developers.google.com/health
- https://developers.google.com/health/reference/rest/v4/users.dataTypes.dataPoints/reconcile
- https://developers.google.com/health/reference/rest/v4/users.dataTypes.dataPoints

### Android Health Connect

Health Connect is an on-device Android API, not a server-side OAuth API. For
Samsung Health data, the phone needs Samsung Health connected to Health Connect,
then a small Android client can read `SleepSessionRecord` and post normalized
sessions to `POST /api/sleep`.

Minimum Android permissions:

```xml
<uses-permission android:name="android.permission.health.READ_SLEEP" />
```

Recommended phone-side sync:

- Request `READ_SLEEP` at runtime.
- Read `SleepSessionRecord` sessions and stages.
- Store a Health Connect changes token and use `getChanges` for incremental
  background sync.
- Upsert sessions by Health Connect record metadata ID through `POST /api/sleep`.
- Send deleted record IDs in `deletedExternalIds`.

Example import payload:

```json
{
  "source": "HEALTH_CONNECT",
  "entries": [
    {
      "externalId": "health-connect-record-id",
      "sourceApp": "Samsung Health",
      "startTime": "2026-06-23T21:45:00.000Z",
      "endTime": "2026-06-24T05:30:00.000Z",
      "sleepMinutes": 430,
      "awakeMinutes": 35,
      "deepMinutes": 80,
      "remMinutes": 95,
      "lightMinutes": 255,
      "stages": [
        {
          "stage": "DEEP",
          "startTime": "2026-06-23T22:20:00.000Z",
          "endTime": "2026-06-23T23:05:00.000Z"
        }
      ]
    }
  ],
  "deletedExternalIds": []
}
```

Reference docs:

- https://developer.android.com/health-and-fitness/health-connect/features/sleep-sessions
- https://developer.android.com/health-and-fitness/health-connect/sync-data
- https://developer.samsung.com/health/blog/en/accessing-samsung-health-data-through-health-connect

## Avoid Google Fit REST for new work

The old Google Fit REST API is not the right target for this integration. Google
is directing new health/fitness data work toward Health Connect and the Google
Health API.
