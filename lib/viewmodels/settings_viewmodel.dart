import 'package:flutter/foundation.dart';
import '../models/settings.dart';
import '../repositories/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsViewModel({required this._repository});

  AppSettings get settings => _repository.settings;

  Future<void> load() {
    return _repository.load().then((_) => notifyListeners());
  }

  Future<void> update(AppSettings settings) {
    return _repository.update(settings).then((_) => notifyListeners());
  }
}
