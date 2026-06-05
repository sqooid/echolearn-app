class AccentOption {
  final String id;
  final String name;
  final String accent; // hex color for accent
  final String onAccent; // hex color for text on accent
  final String swatch; // hex color for swatch display

  const AccentOption({
    required this.id,
    required this.name,
    required this.accent,
    required this.onAccent,
    required this.swatch,
  });
}

class LanguageOption {
  final String id;
  final String name;
  final String native;
  final bool enabled;

  const LanguageOption({
    required this.id,
    required this.name,
    required this.native,
    required this.enabled,
  });
}

class SpacingOption {
  final String id;
  final String label;

  const SpacingOption({required this.id, required this.label});
}

class AppSettings {
  final String lang;
  final String theme;
  final String accent;
  final String spacing;
  final String shadowDelay;

  const AppSettings({
    this.lang = 'jp',
    this.theme = 'light',
    this.accent = 'mono',
    this.spacing = 'cozy',
    this.shadowDelay = 'medium',
  });

  AppSettings copyWith({
    String? lang,
    String? theme,
    String? accent,
    String? spacing,
    String? shadowDelay,
  }) {
    return AppSettings(
      lang: lang ?? this.lang,
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      spacing: spacing ?? this.spacing,
      shadowDelay: shadowDelay ?? this.shadowDelay,
    );
  }
}
