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
  int? _pausedIndex;
  bool _pausedInDelay = false;
  StreamSubscription<List<TranslationCard>>? _sub;

  CardsViewModel({
    required this._repository,
    required this._settings,
    AudioService? audio,
  })  : _audio = audio ?? AudioService() {
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
  bool get isPaused => _pausedIndex != null;
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

  Future<void> load() => _repository.load(_lang);

  Future<void> addCard(String enText) async {
    final card = await _repository.addCard(enText);
    _repository.processCard(card, _lang);
  }

  void updateFilterState(FilterState fs) {
    if (fs.sort != _fs.sort || fs.filter != _fs.filter) {
      _pausedIndex = null;
    }
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

  void editCard(TranslationCard card, TranslationEntry translation, String newEn, String newTranslation) {
    _repository.editCard(card, _lang, newEn, newTranslation);
  }

  void playOne(TranslationCard card, TranslationEntry translation) {
    if (_speakingId == card.id) {
      _stopAll();
      return;
    }
    if (translation.audioData == null) return;
    _stopAllInternal();
    _playToken++;
    final token = _playToken;
    _speakingId = card.id;
    _repository.bumpPlays(card);
    final list = view;
    final idx = list.indexWhere((c) => c.id == card.id);
    _pausedIndex = idx >= 0 ? idx : null;
    _pausedInDelay = false;
    notifyListeners();
    _playAndWait(token, translation.audioData!, () {
      if (_playToken == token) {
        _speakingId = null;
        notifyListeners();
      }
    });
  }

  void toggleListPlayback() {
    if (_listPlaying) {
      _pausedIndex = _currentIndex();
      _pausedInDelay = _speakingId == null;
      _stopAllInternal();
      return;
    }
    _resumeListPlayback();
  }

  void resetAndPlay() {
    _pausedIndex = null;
    _resumeListPlayback();
  }

  void _resumeListPlayback() {
    final v = view;
    if (v.isEmpty) return;
    _stopAllInternal();
    _playToken++;
    final token = _playToken;
    _listPlaying = true;
    _filterOpen = false;
    _expandedId = null;

    int startIdx;
    if (_pausedIndex != null) {
      startIdx = _pausedInDelay ? _pausedIndex! + 1 : _pausedIndex!;
    } else {
      startIdx = 0;
    }
    _pausedIndex = null;
    notifyListeners();
    _playStep(startIdx, token);
  }

  int? _currentIndex() {
    final v = view;
    final idx = v.indexWhere((c) => c.id == (_currentId ?? _speakingId));
    return idx >= 0 ? idx : null;
  }

  void _playStep(int i, int token) {
    if (_playToken != token) return;
    final list = view;
    if (i >= list.length) {
      if (_fs.reshuffle && list.isNotEmpty) {
        final ids = _shuffle(list.map((c) => c.id!).toList());
        _fs = _fs.copyWith(sort: 'shuffle', shuffledIds: ids);
        if (_playToken == token) {
          notifyListeners();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_playToken == token) _playStep(0, token);
          });
        }
        return;
      }
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
    _playAndWait(token, t.audioData!, () {
      if (_playToken != token) return;
      _speakingId = null;
      notifyListeners();
      final delayMs = _shadowDelayMs(card, t);
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (_playToken != token) return;
        _currentId = null;
        notifyListeners();
        _playStep(i + 1, token);
      });
    });
  }

  StreamSubscription<void>? _completeSub;

  void _playAndWait(int token, List<int> audioData, VoidCallback onDone) {
    _completeSub?.cancel();
    _completeSub = _audio.onComplete.listen((_) {
      _completeSub?.cancel();
      onDone();
    });
    _audio.playBytes(Uint8List.fromList(audioData));
  }

  int _shadowDelayMs(TranslationCard card, TranslationEntry translation) {
    final s = _settings.settings;
    var ms = (s.delaySeconds * 1000).round();
    if (s.delayAddClip) {
      ms += translation.durationMs ?? 2000;
    }
    return ms;
  }

  void _stopAll() {
    _pausedIndex = null;
    _stopAllInternal();
  }

  void _stopAllInternal() {
    _playToken++;
    _completeSub?.cancel();
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
