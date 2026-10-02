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
  final List<String> tombstonedLanguages;
  final int translationCount;
  final bool isNew;

  const TranslationCard({
    this.id,
    required this.en,
    required this.createdAt,
    this.plays = 0,
    this.archived = false,
    this.translations = const [],
    this.tombstonedLanguages = const [],
    this.translationCount = 0,
    this.isNew = false,
  });

  TranslationEntry? translationFor(String language) {
    for (final t in translations) {
      if (t.language == language) return t;
    }
    return null;
  }

  bool isTombstoned(String language) => tombstonedLanguages.contains(language);

  bool needsTranslation(String language) =>
      translationFor(language) == null && !isTombstoned(language);

  TranslationCard copyWith({
    int? id,
    String? en,
    int? createdAt,
    int? plays,
    bool? archived,
    List<TranslationEntry>? translations,
    List<String>? tombstonedLanguages,
    int? translationCount,
    bool? isNew,
  }) {
    return TranslationCard(
      id: id ?? this.id,
      en: en ?? this.en,
      createdAt: createdAt ?? this.createdAt,
      plays: plays ?? this.plays,
      archived: archived ?? this.archived,
      translations: translations ?? this.translations,
      tombstonedLanguages: tombstonedLanguages ?? this.tombstonedLanguages,
      translationCount: translationCount ?? this.translationCount,
      isNew: isNew ?? this.isNew,
    );
  }
}
