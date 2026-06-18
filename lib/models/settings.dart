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
  final double delaySeconds;
  final bool delayAddClip;
  final String apiKey;
  final bool confirmDelete;
  final bool scrollToPlaying;

  const AppSettings({
    this.lang = 'jp',
    this.theme = 'light',
    this.accent = 'mono',
    this.spacing = 'cozy',
    this.delaySeconds = 0,
    this.delayAddClip = false,
    this.apiKey = '',
    this.confirmDelete = true,
    this.scrollToPlaying = false,
  });

  AppSettings copyWith({
    String? lang,
    String? theme,
    String? accent,
    String? spacing,
    double? delaySeconds,
    bool? delayAddClip,
    String? apiKey,
    bool? confirmDelete,
    bool? scrollToPlaying,
  }) {
    return AppSettings(
      lang: lang ?? this.lang,
      theme: theme ?? this.theme,
      accent: accent ?? this.accent,
      spacing: spacing ?? this.spacing,
      delaySeconds: delaySeconds ?? this.delaySeconds,
      delayAddClip: delayAddClip ?? this.delayAddClip,
      apiKey: apiKey ?? this.apiKey,
      confirmDelete: confirmDelete ?? this.confirmDelete,
      scrollToPlaying: scrollToPlaying ?? this.scrollToPlaying,
    );
  }
}
