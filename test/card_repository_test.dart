import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lang_app/models/card.dart';
import 'package:lang_app/repositories/card_repository.dart';
import 'package:lang_app/services/api_service.dart';
import 'package:lang_app/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final String _dbFile = p.join(Directory.systemTemp.createTempSync('echolearn_pool_test').path, 'test.db');

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  DatabaseService.overridePath = _dbFile;

  setUp(() async {
    await DatabaseService.close();
    final file = File(_dbFile);
    if (await file.exists()) await file.delete();
  });
  tearDown(() => DatabaseService.close());

  test('backfill runs at most 16 cards concurrently', () async {
    const total = 40;
    for (var i = 0; i < total; i++) {
      await DatabaseService.insertCard(TranslationCard(en: 'phrase $i', createdAt: i));
    }

    var inFlight = 0;
    var maxInFlight = 0;
    var translations = 0;
    var tts = 0;

    final client = MockClient((request) async {
      inFlight++;
      if (inFlight > maxInFlight) maxInFlight = inFlight;
      await Future<void>.delayed(const Duration(milliseconds: 5));
      inFlight--;
      if (request.url.path.endsWith('/translate')) {
        translations++;
        return http.Response(jsonEncode({'text': 'translated'}), 200);
      }
      tts++;
      return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
    });

    final repo = CardRepository(api: ApiService(client: client));
    await repo.load('jp');

    final deadline = DateTime.now().add(const Duration(seconds: 15));
    while (tts < total && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(translations, total);
    expect(tts, total);
    expect(maxInFlight, lessThanOrEqualTo(16), reason: 'pool must cap concurrency at 16');
    expect(maxInFlight, greaterThan(1), reason: 'backfill should actually run in parallel');

    repo.dispose();
  });

  test('manual translate surfaces the loading state before the translation arrives', () async {
    final id = await DatabaseService.insertCard(TranslationCard(en: 'hello', createdAt: 1));
    await DatabaseService.tombstoneMissingTranslations('jp');

    final client = MockClient((request) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (request.url.path.endsWith('/translate')) {
        return http.Response(jsonEncode({'text': 'translated'}), 200);
      }
      return http.Response.bytes(Uint8List.fromList([1, 2, 3]), 200);
    });

    final repo = CardRepository(api: ApiService(client: client));
    await repo.load('jp');

    final states = <String>[];
    final sub = repo.cards.listen((cards) {
      final c = cards.firstWhere((x) => x.id == id);
      states.add('${c.isTombstoned('jp')}:${c.translationFor('jp')?.text ?? ''}');
    });

    final card = (await DatabaseService.getCardWithTranslation(id, 'jp'))!;
    await repo.translateCard(card, 'jp');
    await sub.cancel();

    expect(states.first, 'false:', reason: 'must leave the untranslated state immediately');
    expect(states, contains('false:'));
    expect(states.last, 'false:translated');

    repo.dispose();
  });
}
