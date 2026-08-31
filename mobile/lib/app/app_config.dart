abstract final class AppConfig {
  static const environment = String.fromEnvironment(
    'LUQA_ENV',
    defaultValue: 'development',
  );

  // The deployed API is the default, so a plain `flutter run` works on any
  // device with no port forwarding and no separate development data. Point
  // this at a local server only when a change to the API itself needs testing
  // before it ships:
  //
  //   flutter run --dart-define=LUQA_API_BASE_URL=http://localhost:3000
  //
  // That path additionally needs `adb reverse tcp:3000 tcp:3000`, which has to
  // be re-established after every reconnect.
  static const apiBaseUrl = String.fromEnvironment(
    'LUQA_API_BASE_URL',
    defaultValue: 'https://luqa-pearl.vercel.app',
  );

  static bool get isProduction => environment == 'production';
}
