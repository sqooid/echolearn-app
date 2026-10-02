import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lang_app/models/card.dart';
import 'package:lang_app/repositories/card_repository.dart';
import 'package:lang_app/repositories/settings_repository.dart';
import 'package:lang_app/services/api_service.dart';
import 'package:lang_app/services/database_service.dart';
import 'package:lang_app/viewmodels/cards_viewmodel.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

final String _dbFile = p.join(Directory.systemTemp.createTempSync('echolearn_vm_test').path, 'test.db');

Future<void> _settle() => Future<void>.delayed(Duration.zero);

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

  test('language switch emits old layout once then new, never an intermediate state', () async {
    var apiCalls = 0;
    final api = ApiService(client: MockClient((_) async {
      apiCalls++;
      return http.Response('unexpected', 500);
    }));

    final settingsRepo = SettingsRepository();
    await settingsRepo.load();
    final repo = CardRepository(api: api);

    for (var i = 0; i < 3; i++) {
      await DatabaseService.insertCard(TranslationCard(
        en: 'phrase $i',
        createdAt: i,
        translations: [TranslationEntry(cardId: 0, language: 'jp', text: '訳 $i')],
      ));
    }
    await DatabaseService.setTombstone(1, 'jp');

    final vm = CardsViewModel(repository: repo, settings: settingsRepo);
    await vm.load();
    await _settle();
    expect(vm.untranslatedCount, 1, reason: 'one jp card was tombstoned');

    final counts = <int>[];
    vm.addListener(() => counts.add(vm.untranslatedCount));

    await vm.changeLanguage('ko');
    await _settle();

    expect(settingsRepo.settings.lang, 'ko');
    expect(vm.untranslatedCount, 3, reason: 'all cards tombstoned for ko');
    expect(counts, isNot(contains(0)), reason: 'must not flash the intermediate state');
    expect(counts.last, 3);
    expect(apiCalls, 0, reason: 'switching tombstones rather than back-filling');

    vm.dispose();
    repo.dispose();
  });
}
