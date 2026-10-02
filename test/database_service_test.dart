import 'dart:io';
import 'dart:typed_data';

import 'package:lang_app/models/card.dart';
import 'package:lang_app/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';

final String _dbFile = p.join(Directory.systemTemp.createTempSync('echolearn_db_test').path, 'test.db');

Future<void> _deleteDb() async {
  await DatabaseService.close();
  final file = File(_dbFile);
  if (await file.exists()) await file.delete();
}

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseService.overridePath = _dbFile;

  setUp(_deleteDb);
  tearDown(() => DatabaseService.close());

  test('v2 → v3 migration preserves existing rows', () async {
    final db = await databaseFactory.openDatabase(
      _dbFile,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE cards (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              en TEXT NOT NULL,
              created_at INTEGER NOT NULL,
              plays INTEGER NOT NULL DEFAULT 0,
              archived INTEGER NOT NULL DEFAULT 0
            )
          ''');
          await db.execute('''
            CREATE TABLE translations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              card_id INTEGER NOT NULL,
              language TEXT NOT NULL,
              text TEXT NOT NULL,
              audio_data BLOB,
              duration_ms INTEGER
            )
          ''');
          await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
        },
      ),
    );
    await db.insert('cards', {'en': 'hello', 'created_at': 1});
    await db.insert('translations', {'card_id': 1, 'language': 'jp', 'text': 'こんにちは'});
    await db.close();

    final cards = await DatabaseService.getAllCards('jp');
    expect(cards, hasLength(1));
    expect(cards.single.translationFor('jp')!.text, 'こんにちは');
    expect(cards.single.tombstonedLanguages, isEmpty);
    expect(cards.single.translationCount, 1);
  });

  test('switching language tombstones missing cards instead of back-filling', () async {
    final id = await DatabaseService.insertCard(TranslationCard(en: 'hello', createdAt: 1));
    await DatabaseService.upsertTranslation(
      TranslationEntry(cardId: id, language: 'jp', text: 'こんにちは', audioData: Uint8List.fromList([1, 2, 3])),
    );

    await DatabaseService.tombstoneMissingTranslations('es');

    final es = (await DatabaseService.getAllCards('es')).single;
    expect(es.isTombstoned('es'), isTrue);
    expect(es.translationFor('es'), isNull);
    expect(es.needsTranslation('es'), isFalse);
    expect(es.translationCount, 1);

    final jp = (await DatabaseService.getAllCards('jp')).single;
    expect(jp.isTombstoned('jp'), isFalse);
    expect(jp.translationFor('jp')!.text, 'こんにちは');

    await DatabaseService.clearTombstones('es');
    final cleared = (await DatabaseService.getAllCards('es')).single;
    expect(cleared.isTombstoned('es'), isFalse);
    expect(cleared.needsTranslation('es'), isTrue);
  });

  test('tombstoning a language keeps other translations and the card', () async {
    final id = await DatabaseService.insertCard(TranslationCard(en: 'hello', createdAt: 1));
    await DatabaseService.upsertTranslation(TranslationEntry(cardId: id, language: 'jp', text: 'こんにちは'));
    await DatabaseService.upsertTranslation(TranslationEntry(cardId: id, language: 'es', text: 'hola'));

    await DatabaseService.setTombstone(id, 'es');

    final es = (await DatabaseService.getAllCards('es')).single;
    expect(es.id, id);
    expect(es.translationFor('es'), isNull);
    expect(es.isTombstoned('es'), isTrue);

    final jp = (await DatabaseService.getAllCards('jp')).single;
    expect(jp.translationFor('jp')!.text, 'こんにちは');
    expect(jp.translationCount, 1);

    await DatabaseService.clearTombstone(id, 'es');
    await DatabaseService.upsertTranslation(TranslationEntry(cardId: id, language: 'es', text: 'hola'));
    final es2 = (await DatabaseService.getAllCards('es')).single;
    expect(es2.isTombstoned('es'), isFalse);
    expect(es2.translationFor('es')!.text, 'hola');
    expect(es2.translationCount, 2);
  });

  test('deleting a card removes all translations', () async {
    final id = await DatabaseService.insertCard(TranslationCard(en: 'hi', createdAt: 1));
    await DatabaseService.upsertTranslation(TranslationEntry(cardId: id, language: 'jp', text: 'やあ'));
    await DatabaseService.tombstoneMissingTranslations('es');

    await DatabaseService.deleteCard(id);

    expect(await DatabaseService.getAllCards('jp'), isEmpty);
    expect(await DatabaseService.getAllCards('es'), isEmpty);
  });
}
