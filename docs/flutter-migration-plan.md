# Luqa Flutter migration plan

Status: Flutter foundation and first local vertical slice implemented
Date: 2026-08-27

## Outcome

Luqa becomes a native-first Flutter application for iOS and Android. Neon
Postgres remains the canonical database. The existing web application remains
a supported browser companion on the same Vercel deployment while its
server-side code is turned into a versioned mobile API.

The recommended architecture is deliberately hybrid:

- Flutter owns the product experience, local state, native integrations, and
  offline-friendly behavior.
- The existing web UI remains useful for desktop-oriented workflows, fallback
  access, and operational inspection.
- A small Luqa API owns authentication, authorization, validation,
  transactions, integration secrets, OAuth callbacks, and webhooks.
- Neon Postgres owns durable data.
- Neon Data API is an optional later optimization for carefully selected
  read-only or simple row-level operations, not the application's only backend.

This removes the browser/PWA constraints without moving trusted server logic
into the phone or into a large collection of database functions.

## Why not use Neon Data API directly for everything?

Neon Data API is a credible option for client-side applications: it exposes a
PostgREST-compatible HTTP API, accepts JWT bearer authentication, and relies on
Postgres row-level security. At the time of this plan, Neon documents it as an
open-beta feature and requires RLS for exposed tables.

It is a good fit for ordinary per-user CRUD. Luqa is already beyond ordinary
CRUD:

- Expense writes resolve shares, verify ownership, and atomically replace
  related rows.
- Habit progress can be derived from time entries and logical-day rules.
- Reports combine several models and date boundaries.
- Google Calendar and Google Health integrations hold encrypted refresh tokens
  and receive public callbacks/webhooks.
- Mobile authentication needs refreshable device sessions rather than the
  current browser cookie flow.
- Reliable offline writes need idempotency and conflict handling regardless of
  whether the remote interface is PostgREST or a custom API.

Implementing all of this through direct table access would move application
logic into RLS policies, triggers, and Postgres functions while still leaving a
server deployed for integrations. That is not a real reduction in complexity.

### Decision matrix

| Approach | Strengths | Costs and risks | Decision |
| --- | --- | --- | --- |
| Neon Data API only | Minimal CRUD API code; RLS at the database | Open beta; no Flutter-specific client in the documentation reviewed; complex writes become SQL functions; integrations still need a server | Do not use as the sole backend |
| Flutter + thin Luqa API + Neon | Reuses existing rules; secrets stay server-side; explicit transactions and contracts; easier logging and migration | A small backend remains deployed | Recommended |
| Move to another BaaS | Mature mobile SDKs may be available | Database, auth, and operational migration without removing Luqa's domain logic | No current justification |

References used for the decision:

- [Neon Data API overview](https://neon.com/docs/data-api/get-started)
- [Neon RLS guide](https://neon.com/docs/guides/row-level-security)
- [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide)
- [Flutter offline-first guidance](https://docs.flutter.dev/app-architecture/design-patterns/offline-first)

## Current product inventory

The mobile rewrite must preserve these working product domains rather than
starting from a simplified demo model.

| Domain | Existing behavior to preserve | Mobile opportunity |
| --- | --- | --- |
| Today | Infinite day timeline, timers, categories, sleep editing, logical day start | Native gestures, fast entry, lock-screen/live activity later |
| Habits | Task/count/time goals, varied schedules, category-linked progress, streaks | Haptics, widgets, reminders, offline check-ins |
| Gym | Locations, sessions, free-form set notation, parsed sets, history and progress | One-handed logging, keyboard-aware inputs, keep screen awake |
| Money | People, groups, splits, gifts, settlements, ledgers, paginated history | Fast amount-first flow, contact-quality pickers, reliable local drafts |
| Reports | Time and sleep aggregations | Native charts and drill-downs |
| Life | Life-in-weeks wall, periods, weekly reviews and milestones | Fluid zoom, tactile navigation, richer reflection flow |
| Settings | Preferences, categories, account and integrations | Native account/security and permissions surfaces |
| Integrations | Google Calendar two-way sync and Google Health sync/webhooks | Native calendar/health permission flows where appropriate |

The current database contains 21 models and seven enums. It is already a useful
domain model and should evolve through additive migrations rather than be
replaced.

## Target architecture

```text
Flutter views
    |
    v
Feature view models / controllers
    |
    v
Repositories  <--------------------------+
    |                                     |
    +--> Local database and outbox --------+  immediate reads and writes
    |
    +--> Generated Luqa API client
              |
              v
        Versioned Luqa API
          |           |
          |           +--> OAuth callbacks, webhooks, provider APIs
          v
      Neon Postgres
```

This follows Flutter's current architectural guidance: separate UI and data
layers, use repositories and view models, keep logic out of widgets, use
immutable models and unidirectional data flow, and test each layer separately
and together.

### Flutter application

Initial location: `mobile/`

```text
mobile/
  lib/
    app/                  # bootstrap, router, app shell, environment
    design_system/        # tokens, themes, primitives, motion
    core/                 # networking, database, sync, errors, utilities
    features/
      today/
      habits/
      gym/
      money/
      insights/
      life/
      settings/
  test/
  integration_test/
```

Planned technical direction:

- Material 3 as an accessibility and platform-behavior foundation, with a
  distinct Luqa visual language rather than default Material styling.
- Feature-oriented MVVM with repositories and explicit dependency injection.
- Riverpod as the likely state/DI implementation, subject to a focused package
  review before scaffolding.
- `go_router` for typed, deep-linkable navigation.
- Drift/SQLite as the likely local database, subject to a focused package
  review before the offline phase.
- A generated Dart client from an OpenAPI contract so the Flutter and server
  models cannot silently drift.
- `flutter_secure_storage` or a platform-equivalent secure store for refresh
  credentials; never SQLite or shared preferences.
- Environment-specific API base URLs supplied at build time. No database
  credential or privileged Neon key ships in the app.

### Mobile API

The first implementation should reuse the existing TypeScript/Prisma server
logic instead of immediately rewriting it:

1. Keep the current deployment and add a stable `/api/v1` mobile contract.
2. Extract route-handler logic into framework-independent services where a
   mobile endpoint needs it.
3. Add bearer-token device sessions while preserving the single-owner lock.
4. Publish an OpenAPI document and generate the Dart client.
5. Keep the browser session flow for the web companion and have both clients
   call the same domain services so their behavior cannot drift.

The API and web companion continue to share the Vercel deployment. A separate
server runtime would only be reconsidered if operational evidence justifies the
additional deployment, not merely because Flutter becomes the primary client.

### Authentication

The current credentials flow issues a browser-oriented Auth.js session. Mobile
needs a native session contract:

- The initial login can continue to verify the existing bcrypt password.
- The API returns a short-lived access token and a rotating, revocable refresh
  token tied to one device installation.
- Only a hash of each refresh token is stored server-side.
- The owner-email allowlist remains enforced on every session creation.
- The refresh credential is stored in iOS Keychain / Android Keystore.
- Sign-out revokes the device session; a future security screen can revoke all
  other devices.

Before this is implemented, the exact token format and threat model receive a
separate security review. A managed identity provider remains an option if the
scope expands beyond the current single-owner application.

### Data and synchronization

Neon stays canonical. Offline support is introduced in two deliberate levels:

1. **Local-first reads:** render cached data immediately, refresh in the
   background, then update the cache. This ships with the first vertical slice.
2. **Queued writes:** daily capture actions are written to a local outbox,
   reflected optimistically, and retried with idempotency keys. This follows
   after the API contracts and conflict rules are proven.

Not every operation needs offline mutation. Timeline entries, habit actions,
gym sessions, and expense drafts benefit most. Account, integration, destructive
maintenance, and complex reconciliation actions can remain online-only with a
clear UI state.

Server/data changes expected before queued writes:

- Idempotency keys for commands that may be retried.
- Explicit tombstones or a change log for entities whose deletions must sync.
- Stable server cursors for incremental sync.
- Documented conflict rules. The default can be server-version checked
  last-write-wins for editable notes, while money and destructive operations
  reject stale versions and require reconciliation.
- Transactional endpoints for multi-row aggregates such as expenses and gym
  sessions.

## Product information architecture

Seven equal web navigation destinations should not become seven cramped mobile
tabs. The design phase starts from this proposed shell:

1. **Today** — retrospective timeline logging, optional live timer, sleep, and
   today's habit actions.
2. **Gym** — session logging, exercises, and progress.
3. **Money** — balances, expenses, and settlements.
4. **People** — relationships, groups, person-led context, and ledgers.
5. **Insights** — reports and the life-in-weeks experience.

Habit check-ins stay embedded in Today; tapping the compact strip opens the
full planning, schedule, and habit-insight route. This preserves first-class
habit management without creating a crowded sixth destination. Settings and
Profile are separate actions in the top-right header cluster, with integrations
inside Settings. Deep links and system shortcuts can jump directly into
new-entry flows. The final information architecture will be tested in the
design-system phase before it becomes code.

## Delivery phases

### Phase 0 — Freeze the migration baseline

- Commit or intentionally shelve the current uncommitted web changes.
- Capture production schema and migration state without copying secrets.
- Add API regression tests for the highest-risk domain rules.
- Define feature-parity acceptance criteria from the inventory above.
- Decide whether iOS and Android launch together; the plan assumes both.

Exit condition: the existing app and data behavior are recoverable and the
mobile rewrite has an agreed scope.

### Phase 1 — Design system before product code

- Define Luqa's visual thesis, brand personality, type scale, color system,
  semantic tokens, elevation, shape, spacing, iconography, and motion language.
- Define compact and comfortable density, light/dark themes, accessibility
  contrast, Dynamic Type/text scaling, reduced motion, haptics, and focus states.
- Build and verify Flutter primitives: app shell, navigation, buttons, fields,
  cards, sheets, dialogs, list rows, chips, charts, empty/error/loading/offline
  states, and destructive confirmations.
- Prototype Today, Gym session, Expense entry, and Life wall because together
  they exercise almost every interaction pattern.
- Treat the retrospective [Log time flow](flutter-log-time-flow.md) as Today’s
  primary capture prototype; the live timer is its compact secondary state.
- Add a component gallery and golden tests at representative device sizes.

Exit condition: the key flows look and feel coherent in both themes and at
large text sizes before feature implementation expands.

### Phase 2 — Foundation and first vertical slice

- Create `mobile/` with application environments, routing, theme, logging,
  networking, secure storage, local database, and test foundations.
- Add the versioned mobile auth/session endpoints and generated API client.
- Implement settings/categories and the Today read path.
- Implement one complete write flow, including validation, optimistic feedback,
  retry behavior, and server persistence.

Exit condition: a signed-in user can launch the app, see real Neon-backed data,
perform a core action, restart offline, and still see the correct state.

### Phase 3 — Daily system

- Timeline editing and running timers.
- Sleep display and manual editing.
- Habit day actions, full habit management, schedules, and insights.
  Implemented: `/api/v1/habits` plus `habits`/`habitLogs` in the delta feed,
  a `habits` feature in `mobile/lib/features/habits/`, the check-in strip on
  Today, and the `/habits` route behind it. Which habits a day holds, and
  whether each is done, is resolved on the device from the synced habits,
  logs, and time entries, so the strip is correct with no network. Progress is
  written as the day's resolved state rather than as an action to replay,
  which is what makes a queued check-in safe to retry.
- Calendar integration migration and background refresh behavior.

Exit condition: Flutter can replace the web app for daily use.

### Phase 4 — Gym

- Fast session creation, exercise search/creation, set entry, drafts, and
  history.
- Preserve raw set text as the source entry while retaining parsed sets for
  charts.
- Add keyboard, haptic, keep-awake, and interruption recovery behavior.

Exit condition: a real gym session can be logged one-handed without data loss.

### Phase 5 — Money

- Balances, people/groups, paginated expense history, and ledgers.
- Amount-first expense creation, split modes, gifts, payer selection, editing,
  settlements, and stale-write protection.
- Contract and property tests for exact-cent allocation and balance invariants.

Exit condition: all existing money operations reconcile exactly with the web
implementation against the same test fixtures.

### Phase 6 — Insights and Life

- Native reports and accessible chart alternatives.
- Life wall, periods, reviews, milestones, zoom, and navigation.
- Performance profiling with a full 90-year grid and realistic history.

Exit condition: reports match existing calculations and Life remains fluid on
target devices.

### Phase 7 — Native integrations and release hardening

- Decide the target mapping for Android Health Connect and iOS HealthKit while
  preserving server sync only where it is still needed.
- Background sync, notifications, deep links, app lifecycle recovery, privacy
  copy, crash reporting, and observability.
- Store assets, signing, internal distribution, migration rehearsal, backup and
  rollback runbook.
- Verify the web companion against the same API contracts and keep it available
  for desktop-oriented workflows, fallback access, and operational inspection.

Exit condition: signed release builds pass end-to-end tests on physical iOS and
Android devices, and cutover can be reversed without data loss.

## Quality bar

Every feature slice is complete only when it has:

- Domain and repository unit tests.
- API contract and authorization tests.
- Widget tests for success, loading, empty, offline, and error states.
- Golden tests for the design-system-critical surfaces.
- Integration coverage for its primary user journey.
- Accessibility checks for semantics, contrast, text scaling, touch targets,
  keyboard/focus where applicable, and reduced motion.
- Verified light/dark rendering and small/large phone layouts.
- Real-device performance and interruption testing for capture flows.
- A migration note when it changes persisted data or sync behavior.

## Current local readiness

Verified on 2026-08-27:

- Flutter 3.44.8 stable and Dart 3.12.2 are installed.
- Android SDK 36 is installed and Homebrew OpenJDK 17 is configured in Flutter.
- Xcode 26.6 and CocoaPods 1.17.0 are installed; the iOS 26.5 simulator
  platform still needs to be downloaded through Xcode Settings > Components.
- `mobile/` contains the Android/iOS Flutter scaffold, Riverpod repository
  boundary, go_router app shell, design system, component gallery, Today screen,
  Log time flow, habits, interaction tests, and light/dark goldens.
- The web checkout has extensive uncommitted changes. They must be preserved
  and resolved before any repository-wide move or restructure.

The missing simulator platform is not an Android blocker. The remaining Phase 2
work is the mobile session/API contract, generated client, local cache, and real
Neon-backed vertical slice.

## Decisions to lock before Phase 1 closes

The plan uses these recommended defaults unless changed during review:

- Ship iOS and Android together.
- Keep Neon and the existing data; do not migrate to another backend platform.
- Use a thin API rather than direct Data API access for the initial app.
- Keep the web UI as a supported companion on the shared Vercel deployment.
- Design for offline reads everywhere and queued writes for high-frequency
  capture flows.
- Keep Luqa single-owner for the first mobile release, but avoid architecture
  that prevents future multi-user support.
- Use English as the initial product language and make strings localizable from
  day one.

## Immediate next step

Implement the versioned mobile session plus Categories/Time Entries OpenAPI
contract, then replace `FakeTodayRepository` with remote and local-cache
implementations. Preserve the fake for deterministic widget and golden tests.
