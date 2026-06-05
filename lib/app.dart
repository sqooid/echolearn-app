import 'dart:math';
import 'package:flutter/material.dart';
import 'models/card.dart';
import 'models/settings.dart';
import 'models/filter_state.dart';
import 'data/cards.dart';
import 'utils/theme.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/filter_bar.dart';
import 'widgets/play_fab.dart';
import 'widgets/card_widget.dart';
import 'widgets/dictation_overlay.dart';
import 'widgets/settings_page.dart';

class LingoApp extends StatefulWidget {
  const LingoApp({super.key});

  @override
  State<LingoApp> createState() => _LingoAppState();
}

class _LingoAppState extends State<LingoApp> {
  AppSettings _settings = const AppSettings();
  List<TranslationCard> _cards = [];
  String _page = 'main';
  bool _dictating = false;
  String? _expandedId;
  String? _speakingId;
  String? _currentId;
  bool _listPlaying = false;
  bool _filterOpen = false;
  FilterState _fs = const FilterState();

  final ScrollController _scrollController = ScrollController();
  int _playToken = 0;

  static const double _kItemEstimate = 160;

  @override
  void initState() {
    super.initState();
    _cards = generateCards(count: 520);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<TranslationCard> get _view {
    var v = _cards.where((c) {
      if (_fs.filter == 'all') return true;
      if (_fs.filter == 'archived') return c.archived;
      return !c.archived;
    }).toList();

    if (_fs.query.trim().isNotEmpty) {
      final q = _fs.query.trim().toLowerCase();
      v = v.where((c) =>
          c.en.toLowerCase().contains(q) ||
          c.jp.contains(_fs.query.trim()) ||
          c.romaji.toLowerCase().contains(q)).toList();
    }

    if (_fs.sort == 'shuffle' && _fs.shuffledIds != null) {
      final pos = <String, int>{};
      for (var i = 0; i < _fs.shuffledIds!.length; i++) {
        pos[_fs.shuffledIds![i]] = i;
      }
      v.sort((a, b) => (pos[a.id] ?? 1e9).compareTo(pos[b.id] ?? 1e9));
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

  void _bumpPlays(String id) {
    setState(() {
      _cards = _cards.map((c) => c.id == id ? c.copyWith(plays: c.plays + 1) : c).toList();
    });
  }

  void _stopAll() {
    _playToken++;
    setState(() {
      _listPlaying = false;
      _speakingId = null;
      _currentId = null;
    });
  }

  void _scrollToIndex(int index, {String align = 'start'}) {
    final gap = gapPixels(_settings.spacing);
    var offset = index * (_kItemEstimate + gap);
    if (align == 'center') {
      final viewport = _scrollController.position.viewportDimension;
      offset = offset - viewport / 2 + _kItemEstimate / 2;
    }
    final maxScroll = _scrollController.position.maxScrollExtent;
    _scrollController.animateTo(
      offset.clamp(0.0, maxScroll),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _speak(String text, {int minDur = 1700}) async {
    final duration = max(minDur, text.length * 150);
    await Future.delayed(Duration(milliseconds: duration));
  }

  void _playStep(int i, int token) {
    if (_playToken != token) return;
    final list = _view;
    if (i >= list.length) {
      if (_fs.reshuffle && list.isNotEmpty) {
        final ids = shuffleList(list.map((c) => c.id).toList());
        setState(() => _fs = _fs.copyWith(sort: 'shuffle', shuffledIds: ids));
        Future.delayed(const Duration(milliseconds: 160), () {
          if (_playToken == token) {
          _scrollToIndex(0);
          _playStep(0, token);
          }
        });
        return;
      }
      _stopAll();
      return;
    }
    final card = list[i];
    setState(() {
      _speakingId = card.id;
      _currentId = card.id;
    });
    _bumpPlays(card.id);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToIndex(i, align: 'center');
    });
    _speak(card.jp).then((_) {
      if (_playToken == token) _playStep(i + 1, token);
    });
  }

  void _toggleListPlayback() {
    if (_listPlaying) {
      _stopAll();
      return;
    }
    final view = _view;
    if (view.isEmpty) return;
    _playToken++;
    final token = _playToken;
    setState(() {
      _listPlaying = true;
      _filterOpen = false;
      _expandedId = null;
    });
    _playStep(0, token);
  }

  void _playOne(TranslationCard card) {
    if (_speakingId == card.id) {
      _stopAll();
      return;
    }
    _playToken++;
    final token = _playToken;
    setState(() {
      _listPlaying = false;
      _currentId = null;
      _speakingId = card.id;
    });
    _bumpPlays(card.id);
    _speak(card.jp).then((_) {
      if (_playToken == token) {
        setState(() => _speakingId = null);
      }
    });
  }

  void _onToggleExpand(String id) {
    setState(() => _expandedId = _expandedId == id ? null : id);
  }

  void _onArchive(String id) {
    setState(() {
      _cards = _cards.map((c) => c.id == id ? c.copyWith(archived: true) : c).toList();
      _expandedId = null;
    });
  }

  void _onRestore(String id) {
    setState(() => _cards = _cards.map((c) => c.id == id ? c.copyWith(archived: false) : c).toList());
  }

  void _onDelete(String id) {
    setState(() {
      _cards = _cards.where((c) => c.id != id).toList();
      _expandedId = null;
    });
  }

  void _commitDictation({required String en, required String jp, required String romaji}) {
    final id = 'new${DateTime.now().millisecondsSinceEpoch}';
    final card = TranslationCard(
      id: id,
      en: en,
      jp: '',
      romaji: romaji,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      durationMs: 0,
      plays: 0,
      archived: false,
      status: CardStatus.processing,
      isNew: true,
    );
    setState(() {
      _dictating = false;
      _cards = [card, ..._cards];
      _page = 'main';
      _fs = _fs.copyWith(
        sort: 'newest',
        filter: _fs.filter == 'archived' ? 'active' : _fs.filter,
        query: '',
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 80), () {
        _scrollToIndex(0);
      });
    });
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      setState(() {
        _cards = _cards.map((c) => c.id == id ? c.copyWith(jp: jp, status: CardStatus.ready, isNew: false) : c).toList();
      });
    });
  }

  void _onNav(String p) {
    setState(() {
      _page = p;
      if (p != 'main') _filterOpen = false;
    });
  }

  void _onMic() {
    _stopAll();
    setState(() => _dictating = true);
  }

  Color _resolveAccentColor() {
    for (final a in accentOptions) {
      if (a.id == _settings.accent) return hexToColor(a.accent);
    }
    return const Color(0xFF17171A);
  }

  Color _resolveOnAccentColor() {
    for (final a in accentOptions) {
      if (a.id == _settings.accent) return hexToColor(a.onAccent);
    }
    return const Color(0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _settings.theme == 'dark';
    final colors = isDark ? darkColors : lightColors;
    final accent = _resolveAccentColor();
    final onAccent = _resolveOnAccentColor();
    final density = densityMultiplier(_settings.spacing);
    final gap = gapPixels(_settings.spacing);
    final view = _view;
    final curIdx = max(0, view.indexWhere((c) => c.id == _currentId));

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: colors.screen,
        body: Builder(
          builder: (context) {
            final statusBarHeight = MediaQuery.of(context).padding.top;
            return LingoTheme(
              colors: colors,
              accent: accent,
              onAccent: onAccent,
              density: density,
              gap: gap,
              child: Stack(
                children: [
                  if (_page == 'main') ...[
                    if (view.isEmpty)
                      EmptyState(query: _fs.query)
                    else
                      ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          top: statusBarHeight + 74 + gap,
                          bottom: 120,
                          left: 12,
                          right: 12,
                        ),
                        itemCount: view.length,
                        itemBuilder: (context, index) {
                          final card = view[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: gap),
                            child: TranslationCardWidget(
                              key: ValueKey(card.id),
                              card: card,
                              expanded: _expandedId == card.id,
                              current: _currentId == card.id && _listPlaying,
                              playing: _speakingId == card.id,
                              onToggle: () => _onToggleExpand(card.id),
                              onPlay: () => _playOne(card),
                              onArchive: () => _onArchive(card.id),
                              onDelete: () => _onDelete(card.id),
                              onRestore: () => _onRestore(card.id),
                            ),
                          );
                        },
                      ),
                FilterBar(
                  state: _fs,
                  onChange: (fs) => setState(() => _fs = fs),
                  count: view.length,
                  open: _filterOpen,
                  setOpen: (v) => setState(() => _filterOpen = v),
                ),
                PlayFAB(
                  playing: _listPlaying,
                  onTap: _toggleListPlayback,
                  index: curIdx,
                  total: view.length,
                ),
              ],
              if (_page == 'settings')
                SettingsPage(
                  settings: _settings,
                  onChange: (s) => setState(() => _settings = s),
                ),
              BottomBar(
                page: _page,
                onNavMain: () => _onNav('main'),
                onNavSettings: () => _onNav('settings'),
                onMic: _onMic,
                micActive: _dictating,
              ),
              if (_dictating)
                DictationOverlay(
                  onCommit: _commitDictation,
                  onCancel: () => setState(() => _dictating = false),
                ),
            ],
          ),
        );
      },
    ),
  ),
);
  }
}

Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}
