import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/card.dart';
import 'utils/theme.dart';
import 'viewmodels/cards_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/filter_bar.dart';
import 'widgets/play_fab.dart';
import 'widgets/card_widget.dart';
import 'widgets/dictation_overlay.dart';
import 'widgets/settings_page.dart';

class EchoLearnApp extends StatefulWidget {
  const EchoLearnApp({super.key});

  @override
  State<EchoLearnApp> createState() => _EchoLearnAppState();
}

class _EchoLearnAppState extends State<EchoLearnApp> {
  bool _dictating = false;
  String _page = 'main';
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<String>? _errorSub;
  static const double _kItemEstimate = 160;

  @override
  void dispose() {
    _errorSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIndex(int index, {String align = 'start'}) {
    final settings = context.read<SettingsViewModel>().settings;
    final gap = gapPixels(settings.spacing);
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

  void _deleteCard(BuildContext context, TranslationCard card, CardsViewModel cardsVm, SettingsViewModel settingsVm) {
    if (!settingsVm.settings.confirmDelete) {
      cardsVm.deleteCard(card);
      return;
    }
    final theme = LingoTheme.of(context);
    showDialog(
      context: context,
      builder: (_) => LingoTheme(
        colors: theme.colors,
        accent: theme.accent,
        onAccent: theme.onAccent,
        density: theme.density,
        gap: theme.gap,
        child: ConfirmDialog(
          title: 'Delete card?',
          message: '"${card.en}" will be permanently removed.',
          confirmLabel: 'Delete',
          danger: true,
          onConfirm: () => cardsVm.deleteCard(card),
        ),
      ),
    );
  }

  void _showEditModal(BuildContext context, TranslationCard card, TranslationEntry translation, CardsViewModel cardsVm) {
    final theme = LingoTheme.of(context);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => LingoTheme(
        colors: theme.colors,
        accent: theme.accent,
        onAccent: theme.onAccent,
        density: theme.density,
        gap: theme.gap,
        child: EditCardModal(
          card: card,
          translation: translation,
          onSave: (result) {
            cardsVm.editCard(card, translation, result.en, result.translated);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsVm = context.watch<SettingsViewModel>();
    final cardsVm = context.watch<CardsViewModel>();
    final settings = settingsVm.settings;
    cardsVm.repository.setApiKey(settings.apiKey);

    final isDark = settings.theme == 'dark';
    final colors = isDark ? darkColors : lightColors;
    final accent = _resolveAccentColor(settings.accent);
    final onAccent = _resolveOnAccentColor(settings.accent);
    final density = densityMultiplier(settings.spacing);
    final gap = gapPixels(settings.spacing);
    final view = cardsVm.view;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colors.screen,
        body: Builder(
          builder: (context) {
            final statusBarHeight = MediaQuery.of(context).padding.top;

            // Listen for API errors - context has ScaffoldMessenger here
            _errorSub?.cancel();
            final messenger = ScaffoldMessenger.of(context);
            _errorSub = cardsVm.errors.listen((msg) {
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
              );
            });

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
                      const EmptyState(query: '')
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
                          final t = card.translationFor(settingsVm.settings.lang);
                          return Padding(
                            padding: EdgeInsets.only(bottom: gap),
                            child: TranslationCardWidget(
                              key: ValueKey(card.id),
                              card: card,
                              translation: t,
                              expanded: cardsVm.expandedId == card.id,
                              current: cardsVm.currentId == card.id && cardsVm.listPlaying,
                              playing: cardsVm.speakingId == card.id,
                              onToggle: () => cardsVm.toggleExpand(card.id),
                              onPlay: () => cardsVm.playOne(card, t!),
                              onEdit: () => _showEditModal(context, card, t!, cardsVm),
                              onArchive: () => cardsVm.archiveCard(card),
                              onDelete: () => _deleteCard(context, card, cardsVm, settingsVm),
                              onRestore: () => cardsVm.restoreCard(card),
                            ),
                          );
                        },
                      ),
                    FilterBar(
                      state: cardsVm.filterState,
                      onChange: cardsVm.updateFilterState,
                      count: view.length,
                      open: cardsVm.filterOpen,
                      setOpen: cardsVm.setFilterOpen,
                    ),
                  PlayFAB(
                    playing: cardsVm.listPlaying,
                    isPaused: cardsVm.isPaused,
                    onTap: cardsVm.toggleListPlayback,
                    onReset: cardsVm.resetAndPlay,
                    index: max(0, cardsVm.currentPlayIndex),
                    total: view.length,
                  ),
                  ],
                  if (_page == 'settings')
                    SettingsPage(
                      settings: settingsVm.settings,
                      onChange: (s) => settingsVm.update(s),
                    ),
                  BottomBar(
                    page: _page,
                    onNavMain: () => setState(() => _page = 'main'),
                    onNavSettings: () => setState(() => _page = 'settings'),
                    onMic: () => setState(() => _dictating = true),
                    micActive: _dictating,
                  ),
                  if (_dictating)
                    DictationOverlay(
                      onCommit: (text) {
                        cardsVm.addCard(text);
                        setState(() {
                          _dictating = false;
                          _page = 'main';
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Future.delayed(const Duration(milliseconds: 80), () {
                            _scrollToIndex(0);
                          });
                        });
                      },
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

  Color _resolveAccentColor(String accentId) {
    for (final a in accentOptions) {
      if (a.id == accentId) return hexToColor(a.accent);
    }
    return const Color(0xFF17171A);
  }

  Color _resolveOnAccentColor(String accentId) {
    for (final a in accentOptions) {
      if (a.id == accentId) return hexToColor(a.onAccent);
    }
    return const Color(0xFFFFFFFF);
  }
}

Color hexToColor(String hex) {
  hex = hex.replaceAll('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  return Color(int.parse(hex, radix: 16));
}
