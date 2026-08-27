# Luqa mobile

Android-first Flutter client for Luqa. iOS is scaffolded from the same adaptive
codebase, while the existing Next.js application remains the web companion and
future versioned API host.

## Implemented foundation

- Material 3 light and dark themes derived from `../DESIGN.md`.
- Semantic Luqa colors, spacing, radii, typography, motion, and identity colors.
- Compact `NavigationBar` and expanded `NavigationRail` with five persistent
  go_router branches: Today, Gym, Money, People, and Insights.
- Separate Settings, Profile, and component-gallery routes.
- Native device sign-in with short-lived access tokens, rotating refresh tokens,
  and Android Keystore / iOS Keychain storage.
- Generated, versioned Dart client for the OpenAPI contract in
  `../docs/api/openapi.v1.yaml`.
- Riverpod repository/controller boundary backed by the real `/api/v1` routes
  and an app-private, user-scoped local Today read cache with no credentials.
- Today screen with retrospective capture hierarchy, sleep, compact habits, and
  a category-aware timeline.
- Log time bottom sheet with inferred times, recent activities, category
  search/creation, validation, saving feedback, and server persistence.
- Explicit loading, empty, cached-offline, refresh, expired-session, and error
  states instead of demo data in production.
- Compact/expanded navigation tests, interaction tests, contrast tests, and
  deterministic light/dark golden tests.

Gym, Money, People, and Insights are routed placeholders rather than fake
feature implementations. Habits and sleep remain honest placeholders until
their mobile contracts are connected.

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
the web companion. No Neon connection string or server secret is shipped in the
APK.

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
flutter test --update-goldens test/goldens/today_screen_golden_test.dart
```

## Build-time configuration

No Neon credential or privileged server secret belongs in the app. The public
API origin is injected at build time through `lib/app/app_config.dart`:

```bash
flutter run \
  --dart-define=LUQA_ENV=development \
  --dart-define=LUQA_API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` reaches the host machine from Android Emulator. A physical device
can use the Mac's reachable LAN address while developing. Production builds
refuse a non-HTTPS API origin:

```bash
flutter build apk --release \
  --dart-define=LUQA_ENV=production \
  --dart-define=LUQA_API_BASE_URL=https://your-luqa-domain.example
```

The backend and legacy browser UI continue to deploy together on Vercel. The
mobile client talks only to `/api/v1`; browser Auth.js cookies and native bearer
tokens are deliberately separate.

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
      application/      Riverpod controller and providers
      data/             remote repository, read cache, test fake
      domain/           immutable entry/category models
      presentation/     Today, Log time, picker, timeline
    auth/                native session state, secure credentials, sign-in UI
  core/network/          generated-client adapter and token rotation
packages/luqa_api/       generated OpenAPI Dart client
```

Views depend on controller state, controllers depend on the abstract repository,
and tests override providers with deterministic values. Network and local-cache
implementations can therefore replace the fake without rewriting widgets.

## Next implementation slices

1. Complete timer, edit, and delete actions for time entries.
2. Add mutation idempotency plus a deliberate offline write queue.
3. Connect habits and sleep through versioned mobile endpoints.
4. Replace the Gym placeholder with the next complete vertical slice.
