import '../models/settings.dart';
import '../services/database_service.dart';

class SettingsRepository {
  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  Future<void> load() async {
    _settings = await DatabaseService.loadSettings();
  }

  Future<void> update(AppSettings settings) async {
    _settings = settings;
    await DatabaseService.saveSettings(settings);
  }
}
