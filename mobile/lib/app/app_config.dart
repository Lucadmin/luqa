abstract final class AppConfig {
  static const environment = String.fromEnvironment(
    'LUQA_ENV',
    defaultValue: 'development',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'LUQA_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static bool get isProduction => environment == 'production';
}
