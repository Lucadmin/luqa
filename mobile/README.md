# Luqa mobile

Android-first Flutter client for Luqa. iOS is scaffolded from the same adaptive
codebase, while the existing Next.js application remains the web companion and
future versioned API host.

## Implemented foundation

- Material 3 light and dark themes derived from `../DESIGN.md`.
- Semantic Luqa colors, spacing, radii, typography, motion, and identity colors.
- Compact `NavigationBar` and expanded `NavigationRail` with five persistent
  go_router branches: Today, Gym, Money, People, and Insights — every one of
  them a real destination rather than a placeholder.
- Separate Settings, Profile, and component-gallery routes.
- Native device sign-in with short-lived access tokens, rotating refresh tokens,
  and Android Keystore / iOS Keychain storage.
- Generated, versioned Dart client for the OpenAPI contract in
  `../docs/api/openapi.v1.yaml`, including entry edit/delete and sleep reads.
- Riverpod repository/controller boundary backed by the real `/api/v1` routes
  and an app-private, user-scoped local read cache with no credentials.
- Explicit loading, empty, cached-offline, refresh, expired-session, and error
  states instead of demo data in production.
- Navigation tests, timeline interaction tests, contrast tests, and
  deterministic light/dark golden tests.

### Time tracking

The Today branch is a continuous timeline rather than a single day, matching
the browser companion:

- One pane per calendar day inside a single scroller spanning roughly ten years
  back and a year ahead, with only the days on screen built. The header's date
  label follows the scroll, and its chevrons, date picker, and "back to now"
  control scroll it the other way.
- Data is fetched in three-week windows quantised to whole weeks, so the window
  key only changes every seventh day of scrolling and always keeps a week of
  slack either side of the screen.
- Entries lay out in side-by-side columns when they overlap, clip cleanly at
  midnight so a block crossing it reads as one object, and show untracked
  stretches as a "Fill 45m" pill.
- **Tap any empty part of the grid** to drop a thirty-minute block. It floats
  above the timeline with fingertip-sized handles on each edge; dragging
  resizes in five-minute steps with a haptic tick per step, pulls the timeline
  along near the viewport edges, and a second tap relocates the block rather
  than discarding it. Committing happens in a composer docked under the grid,
  so the block being edited stays visible.
- **Long-press an entry** to lift it back into that same composer for reshaping;
  **tap** it to open the full editor, with delete and an undo snackbar.
- A running timer can be started and stopped from the bar above the grid, and
  the now-line and the running block track the clock once a minute.
- Sleep sessions read from `/api/v1/sleep-entries` sit behind the day as
  measured context. They are not tracked time and stay out of the tracked
  total, but they do occupy the day: a gap never runs through a night, and
  filling the gap beside one starts the moment it ended.
- Tapping a night opens a read-only detail sheet with a hypnogram, a stage
  breakdown, and the derived metrics (efficiency, latency, wake after sleep
  onset, awakenings, midpoint). Corrections belong where the data is recorded,
  so the app does not offer to edit them.

The stage colours are a validated categorical palette, not a hand-picked one.
Sleep depth looks like a job for one hue at three lightnesses, but three steps
of a single hue cannot clear the normal-vision separation floor inside a usable
lightness range. The four stages therefore get four hues, fixed per stage
across both themes, and every segment is directly labelled so identity never
rests on colour alone. See `presentation/widgets/sleep_stage_palette.dart`.

The grid has fixed geometry, so block text is capped at 1.2x scaling and every
block is drawn at least 26 dp high. The full text always reaches a screen
reader through the block's semantics label, and the editor sheet scales without
limit.

### Insights

Insights answers "how did that go" without becoming a dashboard. One focal
object carries the tab — the **rhythm wall** — and everything else is support.

- The wall is one column per day, each running from the day start hour to the
  day start hour, on the same vertical time axis the Today timeline uses. Blocks
  are painted in their category colour at the position they actually happened;
  sleep sits behind them in the shell's own ink, because it is measured rather
  than logged and has no business borrowing an identity colour.
- Totals say how much. The wall says *when*, which is the thing no total can:
  that the working middle of the day has moved, that the evenings went missing
  in March, that the nights drift after a Friday and come back on Monday.
- **Tap a column** and the display number above it moves onto that day, taking
  the breakdown underneath with it; a second tap gives the whole span back. The
  same screen answers "how was this quarter" and "what happened on the ninth".
- Spans are a week, four weeks and twelve weeks, always whole weeks starting on
  a week boundary so the columns line up under the same weekday. Twelve weeks is
  the floor at which a column is still wider than a hairline. The chevrons step
  by whole spans and stop at the one containing today.
- **Where it went** ranks the categories with a bar and a period-over-period
  delta, rather than a ring. A dozen slices of a circle cannot be compared by
  eye, cannot carry their own labels, and leave nowhere to put the number that
  actually matters — whether this is more or less than last time.
- **Patterns** says in words what the wall only implies: the typical shape of a
  day, the average night and its midpoint, how much later that midpoint lands
  after a Friday, the longest unbroken stretch, the fullest hour of the clock,
  the heaviest weekday, days spent with someone, and how much of the elapsed
  span is accounted for at all. Each reading appears only when the data supports
  it — a weekend difference needs a weekday to be different from.
- **Habits** closes the tab with completion against what each schedule actually
  asked for, so a habit due on Mondays is never charged with missing a Tuesday.

Nothing here asks the network a question of its own. The whole tab is a reading
of rows the device already holds, so switching spans is instant and a year of
history reads the same on a train as it does on wifi. Sleep midpoints are
averaged around the evening rather than around midnight — a plain mean of 23:30
and 00:30 comes out at noon — and a day's shape is measured from the blocks that
*began* on it, so a session running past the boundary is not reported as an
early morning.

## Toolchain

Verified on 2026-08-27:

- Flutter 3.44.8 stable / Dart 3.12.2.
- Android SDK 36 and accepted licenses.
- Homebrew OpenJDK 17 configured through `flutter config --jdk-dir`.
- Xcode 26.6 and CocoaPods 1.17.0 installed; `flutter doctor` is clean.
- The iOS 26.5 simulator platform is not installed in Xcode. Download it from
  Xcode Settings > Components before running the simulator build.

The Android application ID and iOS bundle identifier are both
`de.lucadmin.luqa`.

## Run and verify

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Run on an Android device or emulator:

```bash
flutter run
```

The app opens the native sign-in screen and uses the same owner credentials as
the web companion, against the same deployed data the browser sees.

For a physical phone running Android 11 or newer, enable Developer options and
Wireless debugging, then choose **Pair device with pairing code**. On this Mac:

```bash
adb pair <PAIRING_IP:PORT>
adb connect <DEVICE_IP:PORT>
flutter devices
flutter install -d <DEVICE_ID>
```

The pairing and connection ports shown by Android can differ. The Mac and phone
must be on the same Wi-Fi network. After the first pairing, ADB normally
rediscovers the phone automatically while Wireless debugging is enabled.

Regenerate the design-system-critical goldens only after intentionally
reviewing a visual change:

```bash
flutter test --update-goldens test/goldens
```

## Build-time configuration

The app talks to the deployed API by default, so a plain `flutter run` works on
any device with no port forwarding and no separate development data:

```bash
flutter run
```

The public API origin is injected at build time through
`lib/app/app_config.dart` and defaults to `https://luqa-pearl.vercel.app`. No
Neon credential or privileged server secret belongs in the app; the device only
ever holds its own bearer tokens.

Point it at a local server only when a change to the API itself needs testing
before it ships:

```bash
npm run dev            # in the repo root; Next listens on :3000
adb reverse tcp:3000 tcp:3000

flutter run \
  --dart-define=LUQA_ENV=development \
  --dart-define=LUQA_API_BASE_URL=http://localhost:3000
```

`adb reverse` points the device's own `localhost:3000` at the Mac, so the same
origin works on the emulator and on a USB- or Wi-Fi-attached phone, and it
survives changing Wi-Fi networks. **It has to be re-established after every
reconnect or `adb kill-server`.** Without it the device refuses the connection
outright, which the app reports as "Cannot reach http://localhost:3000". The
emulator-only `10.0.2.2` alias is silently dropped on a physical device and
produces the same message.

Cleartext HTTP to `localhost`, `127.0.0.1` and `10.0.2.2` is permitted only in
the debug and profile variants, via
`android/app/src/main/res/xml/network_security_config.xml`. Release builds keep
Android's HTTPS-only default, and refuse a non-HTTPS API origin outright:

```bash
flutter build apk --release \
  --dart-define=LUQA_ENV=production
```

The backend and browser UI deploy together on Vercel. The mobile client talks
only to `/api/v1`; browser Auth.js cookies and native bearer tokens are
deliberately separate.

Regenerate the Dart package after changing the contract:

```bash
cd ..
npm run api:lint
npm run api:generate
```

## Architecture

```text
lib/
  app/                  bootstrap, config, router, adaptive shell
  design_system/        themes, semantic tokens, component gallery
  features/
    today/
      application/      Riverpod timeline controller and providers
      data/             remote repository and app-private read cache
      domain/           entry/sleep/category models, grid geometry and layout
      presentation/     timeline screen, day panes, draft layer, editors
    insights/
      application/      span/offset controller, habit consistency provider
      data/             none — it reads the timeline's own rows
      domain/           span ranges, the rhythm wall's geometry, derived facts
      presentation/     rhythm wall, category ranking, readings, habit strip
    auth/                native session state, secure credentials, sign-in UI
  core/network/          generated-client adapter and token rotation
packages/luqa_api/       generated OpenAPI Dart client
```

Views depend on controller state, controllers depend on the abstract repository,
and tests override providers with deterministic values. Network and local-cache
implementations can therefore replace the fake without rewriting widgets.

## Next implementation slices

1. Add mutation idempotency plus a deliberate offline write queue.
2. Serve the day-start cutoff and other preferences from the settings endpoint
   rather than the `dayStartHour` constant in `timeline_geometry.dart`.
3. Connect habits through a versioned mobile endpoint and give them a home
   outside the timeline chrome.
4. Replace the Gym placeholder with the next complete vertical slice.
