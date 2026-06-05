class TranslationEntry {
  final int? id;
  final int cardId;
  final String language;
  final String text;
  final List<int>? audioData;
  final int? durationMs;

  const TranslationEntry({
    this.id,
    required this.cardId,
    required this.language,
    required this.text,
    this.audioData,
    this.durationMs,
  });

  TranslationEntry copyWith({
    int? id,
    int? cardId,
    String? language,
    String? text,
    List<int>? audioData,
    int? durationMs,
  }) {
    return TranslationEntry(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      language: language ?? this.language,
      text: text ?? this.text,
      audioData: audioData ?? this.audioData,
      durationMs: durationMs ?? this.durationMs,
    );
  }
}

class TranslationCard {
  final int? id;
  final String en;
  final int createdAt;
  final int plays;
  final bool archived;
  final List<TranslationEntry> translations;
  final bool isNew;

  const TranslationCard({
    this.id,
    required this.en,
    required this.createdAt,
    this.plays = 0,
    this.archived = false,
    this.translations = const [],
    this.isNew = false,
  });

  TranslationEntry? translationFor(String language) {
    try {
      return translations.firstWhere((t) => t.language == language);
    } catch (_) {
      return null;
    }
  }

  bool isPendingFor(String language) {
    final t = translationFor(language);
    return t == null || t.text.isEmpty;
  }

  bool isReadyFor(String language) {
    final t = translationFor(language);
    return t != null && t.text.isNotEmpty && t.audioData != null;
  }

  String? get displayText => translations.isNotEmpty ? translations.first.text : null;
  List<int>? get displayAudio => translations.isNotEmpty ? translations.first.audioData : null;
  int? get displayDuration => translations.isNotEmpty ? translations.first.durationMs : null;

  TranslationCard copyWith({
    int? id,
    String? en,
    int? createdAt,
    int? plays,
    bool? archived,
    List<TranslationEntry>? translations,
    bool? isNew,
  }) {
    return TranslationCard(
      id: id ?? this.id,
      en: en ?? this.en,
      createdAt: createdAt ?? this.createdAt,
      plays: plays ?? this.plays,
      archived: archived ?? this.archived,
      translations: translations ?? this.translations,
      isNew: isNew ?? this.isNew,
    );
  }
}
