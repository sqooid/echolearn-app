import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final dbPath = await _dbFilePath();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final backupPath = p.join(tempDir.path, 'echolearn-backup-$timestamp.db');
    await File(dbPath).copy(backupPath);
    await SharePlus.instance.share(ShareParams(
      files: [XFile(backupPath)],
      text: 'EchoLearn backup',
    ));
  }

  static Future<String> _dbFilePath() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'echolearn.db');
  }

  static Future<String?> pickBackupFile() async {
    final result = await FilePicker.pickFiles(type: FileType.any);
    if (result == null || result.files.isEmpty) return null;
    return result.files.single.path;
  }

  static Future<void> restoreBackup(String sourcePath) async {
    await DatabaseService.importBackup(sourcePath);
  }
}
