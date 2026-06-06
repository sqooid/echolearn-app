# AGENTS.md

## Project purpose

**EchoLearn** is a mobile language-learning app built with Flutter. Users dictate phrases in English; the app sends them to a companion API for translation and text-to-speech synthesis, stores results locally in SQLite, and provides a card-based UI for browsing, searching, and sequential playback with shadowing delays.

## Repository structure

The file structure below must be kept in sync. When adding, removing, or repurposing a file, update this map.

```
lib/
  main.dart                     # Entry point, DI setup (repos, services, VMs)
  app.dart                      # Root widget — page routing, list, overlay
  config.dart                   # API_BASE_URL via dart-define (defaults to localhost:8787)

  models/                       # Plain data classes with copyWith()
    card.dart                   # TranslationCard, TranslationEntry
    settings.dart               # AppSettings, AccentOption, LanguageOption
    filter_state.dart           # FilterState (sort, filter, query, shuffledIds)

  services/                     # Platform & network abstractions
    database_service.dart       # SQLite via sqflite (cards, translations, settings tables)
    api_service.dart            # HTTP client for /translate and /tts
    audio_service.dart          # Audio playback wrapper (audioplayers)

  repositories/                 # Business logic, cache, streams
    card_repository.dart        # Card CRUD, translation/TTS pipeline, broadcast stream
    settings_repository.dart    # Settings load/save

  viewmodels/                   # ChangeNotifier state holders for Provider
    cards_viewmodel.dart        # Card list, filter/sort, playback engine, pause/resume
    settings_viewmodel.dart     # Settings mutation

  widgets/                      # Pure UI — no business logic
    bottom_bar.dart             # Persistent nav bar (Cards / Settings / mic)
    card_widget.dart            # Single card: collapsed/expanded/translating states
    dictation_overlay.dart      # Full-screen speech-to-text overlay
    filter_bar.dart             # Collapsible search/filter/sort panel
    frame.dart                  # Device frame chrome (status bar, home pill) — unused
    icons.dart                  # Custom stroke icons via CustomPaint
    oscilloscope.dart           # Animated waveform for dictation UI
    play_fab.dart               # Play/pause/reset FAB with counter pill
    settings_page.dart          # Settings screen (language, theme, accent, spacing, delay, api key)
    virtual_list.dart           # Virtual scrolling list — unused; app uses ListView.builder

  utils/
    theme.dart                  # AppColors, LingoTheme InheritedWidget, density/gap helpers
    time.dart                   # relativeTime(), fullTime() formatters

test/
  widget_test.dart              # Placeholder smoke test

android/app/src/main/
  AndroidManifest.xml           # Permissions: RECORD_AUDIO, INTERNET, WAKE_LOCK
  build.gradle.kts              # Debug builds use applicationIdSuffix ".debug"

ios/Runner/
  Info.plist                    # NSMicrophoneUsageDescription, UIBackgroundModes (audio), NSAppTransportSecurity
```

## Core architecture

```
UI (widgets) → ViewModels (ChangeNotifier) → Repositories → Services (DB / HTTP / Audio)
```

- **ViewModels** are injected via `Provider` in `main.dart`. The `EchoLearnAppRoot` stateful widget initializes all services, repos, and view models, then wraps the app in `MultiProvider`.
- **Data flow**: Cards are loaded from SQLite → cached in `CardRepository._cache` → broadcast via `StreamController` → `CardsViewModel` listens, sets `_cards`, calls `notifyListeners()` → `EchoLearnApp.build()` rebuilds via `context.watch<CardsViewModel>()`.
- **Card translation pipeline**: Dictation creates a card → `CardRepository.processCard()` calls POST /translate → saves result → calls POST /tts → saves audio blob. Translation saves immediately; TTS failure leaves the card ready without audio.
- **Language mapping**: Settings store `lang: 'jp'`. The DB uses the raw settings key as the language identifier. API calls convert via `_languageCode()` (`'jp'` → `'ja'`).
- **Playback engine**: Token-based cancellation. `_playToken` increments to cancel in-flight operations. `_playStep()` drives sequential playback. Audio completion is detected via `AudioService.onComplete` stream. Shadow delay is computed from `delaySeconds` + optional clip duration.

## Development workflow

```bash
# Install dependencies
flutter pub get

# Run (debug, installs as com.example.lang_app.debug on Android)
flutter run --dart-define=API_BASE_URL=http://your-server:8787

# Release build
flutter run --release

# Analyze (required before committing changes)
flutter analyze

# Run tests
flutter test
```

- **No code generation** — the project avoids build_runner. Models use manual `copyWith()` methods.
- **DB migrations**: `DatabaseService` uses sqflite's `onCreate`/`onUpgrade`. Bump the version integer to trigger migrations. The v2 upgrade drops and recreates tables (destructive). **All future migrations must preserve existing data** — use `ALTER TABLE`, `CREATE TABLE IF NOT EXISTS`, and data-copy patterns in `onUpgrade`. Never drop tables unless explicitly approved.
- **API key**: Set in Settings → persisted in DB → synced to `CardRepository._api.apiKey` on startup and settings change.

## Testing guidance

- Tests live in `test/`. Currently only a placeholder exists.
- Use `flutter_test` for widget tests. ViewModels can be tested with `ChangeNotifier` listeners.
- DB-dependent tests need `sqflite_common_ffi` for desktop testing or mock the `DatabaseService`.
- When adding tests, follow: arrange (create VM with mock repo) → act (call VM method) → assert (check state via listener).

## Environment and configuration

| Variable / File | Purpose |
|---|---|
| `--dart-define=API_BASE_URL` | API server base URL (default `http://localhost:8787`) |
| `lib/config.dart` | Reads the dart-define |
| Settings → API key | Stored in SQLite settings table, sent as `x-api-key` header |
| `android/app/build.gradle.kts` | `applicationIdSuffix = ".debug"` for debug builds |

## Common agent tasks

### Adding a UI feature
- New widgets go in `lib/widgets/`. Expose state from `viewmodels/` via getters.
- Wire up in `app.dart` using `context.watch<CardsViewModel>()` or `context.watch<SettingsViewModel>()`.
- Custom icons belong in `lib/widgets/icons.dart` — define a `Path _xPath(Size s)` function and a `class IconX extends StatelessWidget`.

### Adding a new setting
1. Add field to `AppSettings` in `lib/models/settings.dart` (with `copyWith` parameter)
2. Add persistence in `DatabaseService.loadSettings()` and `saveSettings()`
3. Add UI in `SettingsPage` inside `lib/widgets/settings_page.dart`
4. Read it in the VM or App where it's consumed

### Changing the database schema
- Add columns/tables in `_createTables()` in `database_service.dart`
- Bump the `version` integer in `openDatabase()`
- Add migration logic in `onUpgrade` (or use destructive migration like v1→v2)

### Call site of `TranslationCardWidget` — needs `card` + `translation` params
When adding a card to the UI, always pass `card.translationFor(languageCode)` as the `translation:` parameter. The language code comes from `settingsVm.settings.lang` (raw settings key, e.g. `'jp'`).

## Safety notes

- **DB migrations are destructive** between v1 and v2. Bumping the version will drop all data.
- **The `onUpgrade` callback** in `database_service.dart` drops and recreates tables. Do not add incremental migrations without removing the `DROP TABLE` calls. All future migrations must preserve existing data — use `ALTER TABLE`, `CREATE TABLE IF NOT EXISTS`, and data-copy patterns.
- **Audio playback uses token-based cancellation**. Always increment `_playToken` when stopping to prevent stale callbacks.
- **PlayFAB reset logic**: `_pausedIndex` must be set before `_stopAllInternal()` (which clears `_currentId`). The public `_stopAll()` clears `_pausedIndex` — do not call it when pausing; use `_stopAllInternal()` instead.
- **`virtual_list.dart`** is unused. The app uses `ListView.builder` with `ScrollController` and estimated offsets for `scrollToIndex`.

## Style and conventions

- **Naming**: Classes `PascalCase`, variables/functions `camelCase`, private fields `_prefixCamelCase`. File names `snake_case.dart`.
- **State management**: `provider` with `ChangeNotifier`. ViewModels call `notifyListeners()` after mutation. Widgets use `context.watch<>()` to rebuild.
- **Imports**: Group by: `dart:*` → `package:flutter/*` → `package:*` → project imports. Separate with blank lines.
- **No comments** unless the code is non-obvious.
- **Error handling**: API errors are caught and emitted via `CardRepository._errorController` → `CardsViewModel.errors` → shown as `SnackBar` in `app.dart`.
- **Colors**: Use semantic names from `LingoTheme.of(context).colors` (e.g. `theme.colors.ink`, `theme.colors.surface2`). Never hardcode colors in widgets.

## Open questions

- Background playback with screen off is not working reliably. The foreground service attempt was rolled back.
- Tests are minimal — no integration or widget tests exist for the core flows.
