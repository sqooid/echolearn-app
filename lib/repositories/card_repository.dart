import 'dart:async';
import '../models/card.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';

class CardRepository {
  final ApiService _api;
  List<TranslationCard> _cache = [];
  final StreamController<List<TranslationCard>> _controller =
      StreamController<List<TranslationCard>>.broadcast();
  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  CardRepository({ApiService? api}) : _api = api ?? ApiService();

  Stream<List<TranslationCard>> get cards => _controller.stream;
  Stream<String> get errors => _errorController.stream;

  Future<void> load() async {
    _cache = await DatabaseService.getAllCards();
    _controller.add(_cache);
    _processPending('ja');
  }

  void _processPending(String language) {
    for (final card in _cache) {
      if (!card.isReadyFor(language)) {
        processCard(card, language);
      }
    }
  }

  Future<TranslationCard> addCard(String enText) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final card = TranslationCard(
      en: enText,
      createdAt: now,
      plays: 0,
      archived: false,
    );
    final id = await DatabaseService.insertCard(card);
    final inserted = card.copyWith(id: id);
    _cache = [inserted, ..._cache];
    _controller.add(_cache);
    return inserted;
  }

  Future<void> processCard(TranslationCard card, String language) async {
    try {
      final existing = card.translationFor(language);

      if (existing == null) {
        // Need translation
        final translation = await _api.translate(
          text: card.en,
          from: 'en',
          to: _languageCode(language),
        );

        await DatabaseService.upsertTranslation(TranslationEntry(
          cardId: card.id!,
          language: language,
          text: translation.text,
        ));
        await _refreshCard(card.id!);
      }

      // Get fresh card after potential translation save
      final fresh = _cache.firstWhere((c) => c.id == card.id);
      final t = fresh.translationFor(language);
      if (t != null && t.audioData == null) {
        try {
          final audio = await _api.textToSpeech(
            text: t.text,
            language: _languageCode(language),
          );
          final estimatedDuration = (t.text.length * 250).clamp(1500, 30000);
          await DatabaseService.upsertTranslation(TranslationEntry(
            cardId: card.id!,
            language: language,
            text: t.text,
            audioData: audio,
            durationMs: estimatedDuration,
          ));
          await _refreshCard(card.id!);
        } catch (_) {
          // TTS failed — card still usable with translation
        }
      }
    } catch (e) {
      _errorController.add('Failed to process: $e');
    }
  }

  Future<void> _refreshCard(int cardId) async {
    final db = await DatabaseService.database;
    final rows = await db.query('cards', where: 'id = ?', whereArgs: [cardId]);
    if (rows.isEmpty) return;
    final translations = await db.query(
      'translations',
      where: 'card_id = ?',
      whereArgs: [cardId],
    );
    final updated = DatabaseService.rowToCard(rows.first, translations);
    final index = _cache.indexWhere((c) => c.id == cardId);
    if (index >= 0) {
      _cache[index] = updated;
    }
    _controller.add(_cache);
  }

  Future<void> bumpPlays(TranslationCard card) async {
    final updated = card.copyWith(plays: card.plays + 1);
    await DatabaseService.updateCard(updated);
    final index = _cache.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      _cache[index] = updated;
      _controller.add(_cache);
    }
  }

  Future<void> archiveCard(TranslationCard card) async {
    final updated = card.copyWith(archived: true);
    await DatabaseService.updateCard(updated);
    final index = _cache.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      _cache[index] = updated;
      _controller.add(_cache);
    }
  }

  Future<void> restoreCard(TranslationCard card) async {
    final updated = card.copyWith(archived: false);
    await DatabaseService.updateCard(updated);
    final index = _cache.indexWhere((c) => c.id == card.id);
    if (index >= 0) {
      _cache[index] = updated;
      _controller.add(_cache);
    }
  }

  Future<void> deleteCard(TranslationCard card) async {
    await DatabaseService.deleteCard(card.id!);
    _cache.removeWhere((c) => c.id == card.id);
    _controller.add(_cache);
  }

  void dispose() {
    _controller.close();
    _errorController.close();
  }
}

String _languageCode(String settingLang) {
  switch (settingLang) {
    case 'jp': return 'ja';
    case 'ko': return 'ko';
    case 'zh': return 'zh-Hans';
    case 'es': return 'es';
    default: return 'ja';
  }
}
