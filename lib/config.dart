class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.0.11:8787',
  );

  static String get translateUrl => '$apiBaseUrl/translate';
  static String get ttsUrl => '$apiBaseUrl/tts';
}
