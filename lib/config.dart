class AppConfig {
  static const bool _isRelease = bool.fromEnvironment('dart.vm.product');

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        _isRelease ? 'https://echolearn-api.thesqooid.com' : 'http://192.168.0.11:8787',
  );

  static String get translateUrl => '$apiBaseUrl/translate';
  static String get ttsUrl => '$apiBaseUrl/tts';
}
