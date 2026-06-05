import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/filter_state.dart';
import '../repositories/card_repository.dart';
import '../repositories/settings_repository.dart';
import '../services/audio_service.dart';

List<T> _shuffle<T>(List<T> list) {
  final result = List<T>.from(list);
  final rng = Random();
  for (var i = result.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = result[i];
    result[i] = result[j];
    result[j] = tmp;
  }
  return result;
}

class CardsViewModel extends ChangeNotifier {
  final CardRepository _repository;
  final SettingsRepository _settings;
  final AudioService _audio;

  List<TranslationCard> _cards = [];
  int? _expandedId;
  int? _speakingId;
  int? _currentId;
  bool _listPlaying = false;
  bool _filterOpen = false;
  FilterState _fs = const FilterState();
  int _playToken = 0;
  StreamSubscription<List<TranslationCard>>? _sub;

  CardsViewModel({
    required CardRepository repository,
    required SettingsRepository settings,
    AudioService? audio,
  })  : _repository = repository,
        _settings = settings,
        _audio = audio ?? AudioService() {
    _sub = _repository.cards.listen((cards) {
      _cards = cards;
      notifyListeners();
    });
  }

  String get _lang => _settings.settings.lang;

  List<TranslationCard> get cards => _cards;
  CardRepository get repository => _repository;
  int? get expandedId => _expandedId;
  int? get speakingId => _speakingId;
  int? get currentId => _currentId;
  bool get listPlaying => _listPlaying;
  bool get filterOpen => _filterOpen;
  FilterState get filterState => _fs;
  Stream<String> get errors => _repository.errors;

  List<TranslationCard> get view {
    var v = _cards.where((c) {
      if (_fs.filter == 'all') return true;
      if (_fs.filter == 'archived') return c.archived;
      return !c.archived;
    }).toList();

    if (_fs.query.trim().isNotEmpty) {
      final q = _fs.query.trim().toLowerCase();
      v = v.where((c) =>
          c.en.toLowerCase().contains(q) ||
          (c.translations.isNotEmpty &&
              c.translations.first.text.toLowerCase().contains(q))).toList();
    }

    if (_fs.sort == 'shuffle' && _fs.shuffledIds != null) {
      final pos = <int, int>{};
      for (var i = 0; i < _fs.shuffledIds!.length; i++) {
        pos[_fs.shuffledIds![i]] = i;
      }
      v.sort((a, b) => (pos[a.id!] ?? 1e9).compareTo(pos[b.id!] ?? 1e9));
    } else if (_fs.sort == 'newest') {
      v.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_fs.sort == 'oldest') {
      v.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_fs.sort == 'az') {
      v.sort((a, b) => a.en.compareTo(b.en));
    } else if (_fs.sort == 'za') {
      v.sort((a, b) => b.en.compareTo(a.en));
    }

    return v;
  }

  Future<void> load() => _repository.load(_languageCode(_lang));

// At bottom of file (outside class) add:
String _languageCode(String settingLang) {
  switch (settingLang) {
    case 'jp': return 'ja';
    case 'ko': return 'ko';
    case 'zh': return 'zh-Hans';
    case 'es': return 'es';
    default: return 'ja';
  }
}

  Future<void> addCard(String enText) async {
    final card = await _repository.addCard(enText);
    _repository.processCard(card, _lang);
  }

  void updateFilterState(FilterState fs) {
    _fs = fs;
    notifyListeners();
  }

  void setFilterOpen(bool v) {
    _filterOpen = v;
    notifyListeners();
  }

  void toggleExpand(int? id) {
    _expandedId = _expandedId == id ? null : id;
    notifyListeners();
  }

  void archiveCard(TranslationCard card) {
    _repository.archiveCard(card);
    _expandedId = null;
    notifyListeners();
  }

  void restoreCard(TranslationCard card) {
    _repository.restoreCard(card);
  }

  void deleteCard(TranslationCard card) {
    _repository.deleteCard(card);
    _expandedId = null;
  }

  void playOne(TranslationCard card, TranslationEntry translation) {
    if (_speakingId == card.id) {
      _stopAll();
      return;
    }
    if (translation.audioData == null) return;
    _playToken++;
    final token = _playToken;
    _listPlaying = false;
    _currentId = null;
    _speakingId = card.id;
    _repository.bumpPlays(card);
    notifyListeners();
    _playAudio(token, card, translation);
  }

  void toggleListPlayback() {
    if (_listPlaying) {
      _stopAll();
      return;
    }
    final v = view;
    if (v.isEmpty) return;
    _playToken++;
    final token = _playToken;
    _listPlaying = true;
    _filterOpen = false;
    _expandedId = null;
    notifyListeners();
    _playStep(0, token);
  }

  void _playStep(int i, int token) {
    if (_playToken != token) return;
    final list = view;
    if (i >= list.length) {
      if (_fs.reshuffle && list.isNotEmpty) {
        final ids = _shuffle(list.map((c) => c.id!).toList());
        _fs = _fs.copyWith(sort: 'shuffle', shuffledIds: ids);
        notifyListeners();
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_playToken == token) _playStep(0, token);
        });
        return;
      }
      // Always loop back to start
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_playToken == token) _playStep(0, token);
      });
      return;
    }
    final card = list[i];
    final t = card.translationFor(_lang);
    if (t == null || t.audioData == null) {
      _playStep(i + 1, token);
      return;
    }
    _speakingId = card.id;
    _currentId = card.id;
    _repository.bumpPlays(card);
    notifyListeners();
    _playAudio(token, card, t);
  }

  Future<void> _playAudio(int token, TranslationCard card, TranslationEntry translation) async {
    if (translation.audioData == null) return;
    try {
      await _audio.playBytes(Uint8List.fromList(translation.audioData!));
    } catch (_) {
      // fall through to delay
    }
    // Shadowing delay between cards
    final delayMs = _shadowDelayMs(card, translation);
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    _onAudioComplete();
  }

  int _shadowDelayMs(TranslationCard card, TranslationEntry translation) {
    final setting = _settings.settings.shadowDelay;
    switch (setting) {
      case 'none': return 0;
      case 'short': return 1500;
      case 'medium': return 3000;
      case 'long': return 5000;
      case 'clip': return (translation.durationMs ?? 2000) ~/ 2;
      default: return 3000;
    }
  }

  void _onAudioComplete() {
    if (!_listPlaying) {
      _speakingId = null;
      notifyListeners();
      return;
    }
    final list = view;
    final idx = list.indexWhere((c) => c.id == _speakingId);
    final nextIdx = (idx < 0 || idx >= list.length - 1) ? list.length : idx + 1;
    _playStep(nextIdx, _playToken);
  }

  void _stopAll() {
    _playToken++;
    _audio.stop();
    _listPlaying = false;
    _speakingId = null;
    _currentId = null;
    notifyListeners();
  }

  int get currentPlayIndex {
    final v = view;
    return v.indexWhere((c) => c.id == _currentId);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _audio.dispose();
    super.dispose();
  }
}
