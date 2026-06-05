enum CardStatus { ready, dictating, processing }

class TranslationCard {
  final String id;
  final String en;
  final String jp;
  final String romaji;
  final int createdAt;
  final int durationMs;
  final int plays;
  final bool archived;
  final CardStatus status;
  final bool isNew;

  const TranslationCard({
    required this.id,
    required this.en,
    required this.jp,
    required this.romaji,
    required this.createdAt,
    required this.durationMs,
    required this.plays,
    required this.archived,
    required this.status,
    this.isNew = false,
  });

  TranslationCard copyWith({
    String? id,
    String? en,
    String? jp,
    String? romaji,
    int? createdAt,
    int? durationMs,
    int? plays,
    bool? archived,
    CardStatus? status,
    bool? isNew,
  }) {
    return TranslationCard(
      id: id ?? this.id,
      en: en ?? this.en,
      jp: jp ?? this.jp,
      romaji: romaji ?? this.romaji,
      createdAt: createdAt ?? this.createdAt,
      durationMs: durationMs ?? this.durationMs,
      plays: plays ?? this.plays,
      archived: archived ?? this.archived,
      status: status ?? this.status,
      isNew: isNew ?? this.isNew,
    );
  }
}
