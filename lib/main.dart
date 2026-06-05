import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/api_service.dart';
import 'repositories/card_repository.dart';
import 'repositories/settings_repository.dart';
import 'viewmodels/cards_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LingoAppRoot());
}

class LingoAppRoot extends StatefulWidget {
  const LingoAppRoot({super.key});

  @override
  State<LingoAppRoot> createState() => _LingoAppRootState();
}

class _LingoAppRootState extends State<LingoAppRoot> {
  late final CardRepository _cardRepo;
  late final SettingsRepository _settingsRepo;
  late final CardsViewModel _cardsVm;
  late final SettingsViewModel _settingsVm;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await DatabaseService.database; // ensure DB is created
    _cardRepo = CardRepository(api: ApiService());
    _settingsRepo = SettingsRepository();
    _cardsVm = CardsViewModel(repository: _cardRepo, settings: _settingsRepo);
    _settingsVm = SettingsViewModel(repository: _settingsRepo);

    await _settingsVm.load();
    _cardRepo.setApiKey(_settingsVm.settings.apiKey);
    await _cardsVm.load();

    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _cardsVm),
        ChangeNotifierProvider.value(value: _settingsVm),
      ],
      child: const LingoApp(),
    );
  }
}
