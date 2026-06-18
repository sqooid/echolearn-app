import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/card.dart';
import '../models/settings.dart';

class DatabaseService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'echolearn.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS translations (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              card_id INTEGER NOT NULL,
              language TEXT NOT NULL,
              text TEXT NOT NULL,
              audio_data BLOB,
              duration_ms INTEGER,
              FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
            )
          ''');
          try { await db.execute('ALTER TABLE cards ADD COLUMN plays INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE cards ADD COLUMN archived INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
        }
      },
      onDowngrade: (db, oldVersion, newVersion) async {
        await db.execute('DROP TABLE IF EXISTS cards');
        await db.execute('DROP TABLE IF EXISTS translations');
        await db.execute('DROP TABLE IF EXISTS settings');
        await _createTables(db);
      },
    );
  }

  static Future<void> _createTables(Database db) async {
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
        duration_ms INTEGER,
        FOREIGN KEY (card_id) REFERENCES cards(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── Cards ──

  static Future<int> insertCard(TranslationCard card) async {
    final db = await database;
    final id = await db.insert('cards', {
      'en': card.en,
      'created_at': card.createdAt,
      'plays': card.plays,
      'archived': card.archived ? 1 : 0,
    });
    for (final t in card.translations) {
      await db.insert('translations', {
        'card_id': id,
        'language': t.language,
        'text': t.text,
        'audio_data': t.audioData,
        'duration_ms': t.durationMs,
      });
    }
    return id;
  }

  static Future<void> updateCard(TranslationCard card) async {
    final db = await database;
    await db.update(
      'cards',
      {
        'en': card.en,
        'plays': card.plays,
        'archived': card.archived ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  static Future<void> upsertTranslation(TranslationEntry entry) async {
    final db = await database;
    final existing = await db.query(
      'translations',
      where: 'card_id = ? AND language = ?',
      whereArgs: [entry.cardId, entry.language],
    );
    if (existing.isEmpty) {
      await db.insert('translations', {
        'card_id': entry.cardId,
        'language': entry.language,
        'text': entry.text,
        'audio_data': entry.audioData,
        'duration_ms': entry.durationMs,
      });
    } else {
      await db.update(
        'translations',
        {
          'text': entry.text,
          'audio_data': entry.audioData,
          'duration_ms': entry.durationMs,
        },
        where: 'card_id = ? AND language = ?',
        whereArgs: [entry.cardId, entry.language],
      );
    }
  }

  static Future<void> deleteCard(int id) async {
    final db = await database;
    await db.delete('translations', where: 'card_id = ?', whereArgs: [id]);
    await db.delete('cards', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<TranslationCard>> getAllCards(String language) async {
    final db = await database;
    final cardRows = await db.query('cards', orderBy: 'created_at DESC');
    final translations = await db.query('translations', where: 'language = ?', whereArgs: [language]);
    return _buildCards(cardRows, translations);
  }

  static Future<TranslationCard?> getCardWithTranslation(int cardId, String language) async {
    final db = await database;
    final cardRows = await db.query('cards', where: 'id = ?', whereArgs: [cardId]);
    if (cardRows.isEmpty) return null;
    final translations = await db.query('translations', where: 'card_id = ? AND language = ?', whereArgs: [cardId, language]);
    return _buildCards(cardRows, translations).first;
  }

  static List<TranslationCard> _buildCards(List<Map<String, dynamic>> cardRows, List<Map<String, dynamic>> translations) {
    final transByCard = <int, List<TranslationEntry>>{};
    for (final t in translations) {
      final cardId = t['card_id'] as int;
      transByCard.putIfAbsent(cardId, () => []).add(TranslationEntry(
        id: t['id'] as int,
        cardId: cardId,
        language: t['language'] as String,
        text: t['text'] as String,
        audioData: t['audio_data'] != null ? List<int>.from(t['audio_data'] as List) : null,
        durationMs: t['duration_ms'] as int?,
      ));
    }
    return cardRows.map((row) {
      final id = row['id'] as int;
      return TranslationCard(
        id: id,
        en: row['en'] as String,
        createdAt: row['created_at'] as int,
        plays: row['plays'] as int,
        archived: (row['archived'] as int) == 1,
        translations: transByCard[id] ?? [],
      );
    }).toList();
  }

  // ── Settings ──

  static Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  static Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<AppSettings> loadSettings() async {
    final lang = await getSetting('lang') ?? 'jp';
    final theme = await getSetting('theme') ?? 'light';
    final accent = await getSetting('accent') ?? 'mono';
    final spacing = await getSetting('spacing') ?? 'cozy';
    final delaySeconds = double.tryParse(await getSetting('delaySeconds') ?? '0') ?? 0;
    final delayAddClip = (await getSetting('delayAddClip') ?? 'false') == 'true';
    final apiKey = await getSetting('apiKey') ?? '';
    final confirmDelete = (await getSetting('confirmDelete') ?? 'true') == 'true';
    final scrollToPlaying = (await getSetting('scrollToPlaying') ?? 'false') == 'true';
    return AppSettings(
      lang: lang,
      theme: theme,
      accent: accent,
      spacing: spacing,
      delaySeconds: delaySeconds,
      delayAddClip: delayAddClip,
      apiKey: apiKey,
      confirmDelete: confirmDelete,
      scrollToPlaying: scrollToPlaying,
    );
  }

  static Future<void> saveSettings(AppSettings settings) async {
    await setSetting('lang', settings.lang);
    await setSetting('theme', settings.theme);
    await setSetting('accent', settings.accent);
    await setSetting('spacing', settings.spacing);
    await setSetting('delaySeconds', settings.delaySeconds.toString());
    await setSetting('delayAddClip', settings.delayAddClip.toString());
    await setSetting('apiKey', settings.apiKey);
    await setSetting('confirmDelete', settings.confirmDelete.toString());
    await setSetting('scrollToPlaying', settings.scrollToPlaying.toString());
  }

  static Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  static Future<void> importBackup(String sourcePath) async {
    await close();
    final dbPath = await getDatabasesPath();
    final targetPath = join(dbPath, 'echolearn.db');
    final source = File(sourcePath);
    await source.copy(targetPath);
  }
}
