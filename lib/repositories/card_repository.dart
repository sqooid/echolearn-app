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
  final List<_ProcessJob> _processQueue = [];
  int _activeProcesses = 0;

  static const int _maxConcurrentProcesses = 16;

  CardRepository({ApiService? api}) : _api = api ?? ApiService();

  Stream<List<TranslationCard>> get cards => _controller.stream;
  Stream<String> get errors => _errorController.stream;

  void setApiKey(String key) {
    _api.apiKey = key;
  }

  Future<void> load(String language) async {
    _cache = await DatabaseService.getAllCards(language);
    _controller.add(_cache);
    _processPending(language);
  }

  void _processPending(String language) {
    for (final card in _cache) {
      if (card.needsTranslation(language)) {
        processCard(card, language);
      }
    }
  }

  Future<void> changeLanguage(String language) async {
    await DatabaseService.tombstoneMissingTranslations(language);
    await load(language);
  }

  Future<void> translateCard(TranslationCard card, String language) async {
    await DatabaseService.clearTombstone(card.id!, language);
    // Surface the loading state immediately: the card is no longer tombstoned
    // (untranslated) but has no translation yet, so the card shows its
    // "translating" state instead of staying on the Translate button.
    await _refreshCard(card.id!, language);
    await processCard(card, language, prioritize: true);
  }

  Future<void> translateMissing(String language) async {
    await DatabaseService.clearTombstones(language);
    await load(language);
  }

  Future<void> deleteTranslation(TranslationCard card, String language) async {
    await DatabaseService.setTombstone(card.id!, language);
    await _refreshCard(card.id!, language);
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

  /// Queues a card for translation/TTS. At most [_maxConcurrentProcesses] cards
  /// run concurrently, so no more than that many translate/TTS requests are ever
  /// in flight. [prioritize] jumps the queue for user-initiated work.
  Future<void> processCard(TranslationCard card, String language, {bool prioritize = false}) {
    final completer = Completer<void>();
    final job = _ProcessJob(card, language, completer);
    if (prioritize) {
      _processQueue.insert(0, job);
    } else {
      _processQueue.add(job);
    }
    _pumpProcessQueue();
    return completer.future;
  }

  void _pumpProcessQueue() {
    while (_activeProcesses < _maxConcurrentProcesses && _processQueue.isNotEmpty) {
      final job = _processQueue.removeAt(0);
      _activeProcesses++;
      _processCard(job.card, job.language).whenComplete(() {
        _activeProcesses--;
        job.completer.complete();
        _pumpProcessQueue();
      });
    }
  }

  Future<void> _processCard(TranslationCard card, String language) async {
    if (!_cache.any((c) => c.id == card.id)) return;
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
        await _refreshCard(card.id!, language);
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
          await _refreshCard(card.id!, language);
        } catch (_) {
          // TTS failed — card still usable with translation
        }
      }
    } catch (e) {
      _errorController.add('Failed to process: $e');
    }
  }

  Future<void> repairCardAudio(TranslationCard card, String language) async {
    final t = card.translationFor(language);
    if (t == null || t.audioData == null) return;
    await DatabaseService.upsertTranslation(TranslationEntry(
      cardId: card.id!,
      language: language,
      text: t.text,
      audioData: null,
      durationMs: null,
    ));
    await _refreshCard(card.id!, language);
    processCard(card, language, prioritize: true);
  }

  Future<void> _refreshCard(int cardId, String language) async {
    final updated = await DatabaseService.getCardWithTranslation(cardId, language);
    if (updated == null) return;
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

  Future<void> editCard(TranslationCard card, String language, String newEn, String newTranslation) async {
    final enChanged = card.en != newEn;
    final t = card.translationFor(language);
    final trChanged = t != null && t.text != newTranslation;

    if (!enChanged && !trChanged) return;

    if (enChanged) {
      await DatabaseService.updateCard(card.copyWith(en: newEn));
    }

    if (trChanged) {
      List<int>? audioData = t.audioData;
      int? durationMs = t.durationMs;
      try {
        audioData = await _api.textToSpeech(text: newTranslation, language: _languageCode(language));
        durationMs = (newTranslation.length * 250).clamp(1500, 30000);
      } catch (_) {}

      await DatabaseService.upsertTranslation(TranslationEntry(
        cardId: card.id!,
        language: language,
        text: newTranslation,
        audioData: audioData,
        durationMs: durationMs,
      ));
    }

    await _refreshCard(card.id!, language);
  }

  void dispose() {
    for (final job in _processQueue) {
      if (!job.completer.isCompleted) job.completer.complete();
    }
    _processQueue.clear();
    _controller.close();
    _errorController.close();
  }
}

class _ProcessJob {
  final TranslationCard card;
  final String language;
  final Completer<void> completer;

  const _ProcessJob(this.card, this.language, this.completer);
}

String _languageCode(String settingLang) {
  // Map settings key to API language code for TTS/translate calls.
  // Must be a BCP-47 code the server accepts: ja, ko, zh-Hans (Mandarin).
  switch (settingLang) {
    case 'jp': return 'ja';
    case 'ko': return 'ko';
    case 'zh': return 'zh-Hans';
    default: return 'ja';
  }
}
