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
- Riverpod repository/controller boundary with a replaceable fake repository.
- Today screen with retrospective capture hierarchy, sleep, compact habits, and
  a category-aware timeline.
- Log time bottom sheet with inferred times, recent activities, category
  search/creation, validation, saving feedback, and local timeline insertion.
- Compact/expanded navigation tests, interaction tests, contrast tests, and
  deterministic light/dark golden tests.

Gym, Money, People, and Insights are routed placeholders rather than fake
feature implementations. The next vertical slice replaces the Today fake
repository with the generated `/api/v1` client and local cache.

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

No Neon credential or privileged server secret belongs in the app. Future API
code reads public environment values through `lib/app/app_config.dart`:

```bash
flutter run \
  --dart-define=LUQA_ENV=development \
  --dart-define=LUQA_API_BASE_URL=http://10.0.2.2:3000
```

`10.0.2.2` reaches the host machine from Android Emulator. A physical device
needs a reachable HTTPS development endpoint or LAN address.

## Architecture

```text
lib/
  app/                  bootstrap, config, router, adaptive shell
  design_system/        themes, semantic tokens, component gallery
  features/
    today/
      application/      Riverpod controller and providers
      data/             repository contract and current fake
      domain/           immutable entry/category models
      presentation/     Today, Log time, picker, timeline
```

Views depend on controller state, controllers depend on the abstract repository,
and tests override providers with deterministic values. Network and local-cache
implementations can therefore replace the fake without rewriting widgets.

## Next implementation slice

1. Add mobile device-session endpoints under `/api/v1/auth`.
2. Publish the first OpenAPI contract for categories and time entries.
3. Generate the Dart client and implement the remote Today repository.
4. Add a local read cache, mutation ids, and explicit pending-sync state.
5. Replace demo entries only after the signed-in API path passes end to end.
