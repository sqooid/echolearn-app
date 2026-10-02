import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lang_app/models/card.dart';
import 'package:lang_app/utils/theme.dart';
import 'package:lang_app/widgets/card_widget.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: LingoTheme(
        colors: lightColors,
        accent: const Color(0xFF3B82F6),
        onAccent: Colors.white,
        density: 1,
        gap: 12,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

TranslationCard _card({required int count}) => TranslationCard(
      id: 1,
      en: 'hello',
      createdAt: 0,
      translationCount: count,
    );

void main() {
  testWidgets('untranslated card shows Translate and fires callback', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(_wrap(TranslationCardWidget(
      card: _card(count: 0),
      translation: null,
      languageName: 'Japanese',
      untranslated: true,
      expanded: false,
      current: false,
      playing: false,
      onToggle: () {},
      onPlay: () {},
      onEdit: () {},
      onArchive: () {},
      onDelete: () {},
      onRestore: () {},
      onTranslate: () => tapped++,
      onDeleteTranslation: () {},
    )));
    expect(find.text('Not translated'), findsOneWidget);
    await tester.tap(find.text('Translate'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('translating label reflects the current language', (tester) async {
    await tester.pumpWidget(_wrap(TranslationCardWidget(
      card: _card(count: 0),
      translation: null,
      languageName: 'Korean',
      expanded: false,
      current: false,
      playing: false,
      onToggle: () {},
      onPlay: () {},
      onEdit: () {},
      onArchive: () {},
      onDelete: () {},
      onRestore: () {},
      onTranslate: () {},
      onDeleteTranslation: () {},
    )));
    expect(find.text('Translating to Korean…'), findsOneWidget);
  });

  testWidgets('delete-translation action only shows with multiple translations', (tester) async {
    await tester.pumpWidget(_wrap(TranslationCardWidget(
      card: _card(count: 2),
      translation: const TranslationEntry(cardId: 1, language: 'jp', text: 'こんにちは'),
      languageName: 'Japanese',
      expanded: true,
      current: false,
      playing: false,
      onToggle: () {},
      onPlay: () {},
      onEdit: () {},
      onArchive: () {},
      onDelete: () {},
      onRestore: () {},
      onTranslate: () {},
      onDeleteTranslation: () {},
    )));
    expect(find.byTooltip('Delete translation'), findsOneWidget);

    await tester.pumpWidget(_wrap(TranslationCardWidget(
      card: _card(count: 1),
      translation: const TranslationEntry(cardId: 1, language: 'jp', text: 'こんにちは'),
      languageName: 'Japanese',
      expanded: true,
      current: false,
      playing: false,
      onToggle: () {},
      onPlay: () {},
      onEdit: () {},
      onArchive: () {},
      onDelete: () {},
      onRestore: () {},
      onTranslate: () {},
      onDeleteTranslation: () {},
    )));
    expect(find.byTooltip('Delete translation'), findsNothing);
  });
}
