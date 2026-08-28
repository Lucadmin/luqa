abstract final class AppConfig {
  static const environment = String.fromEnvironment(
    'LUQA_ENV',
    defaultValue: 'development',
  );

  // `localhost` works on both the emulator and a USB-attached physical device
  // once `adb reverse tcp:3000 tcp:3000` forwards the port to the dev machine.
  // The emulator-only `10.0.2.2` alias is unroutable from a real phone.
  static const apiBaseUrl = String.fromEnvironment(
    'LUQA_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static bool get isProduction => environment == 'production';
}
