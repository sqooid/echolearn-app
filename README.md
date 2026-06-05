# EchoLearn

A mobile language-learning app for dictation, translation, and spaced listening practice. Built with Flutter.

> **v0.1 — Prerelease** · Expect rough edges. See the [release notes](https://github.com/anomalyco/lang-app/releases/tag/v0.1).

## Features

- **Dictation** — Speak a phrase in English; speech-to-text captures your words live.
- **Auto-translation** — Dictated phrases are sent to a configurable API for translation.
- **TTS audio** — Synthesized audio for each translation, stored locally for offline playback.
- **Playback queue** — Play all cards sequentially with configurable shadowing delays. Pause/resume preserves position; a reset button restarts from the beginning.
- **Card management** — Archive, restore, delete. Expand for metadata. Search, filter (active / all / archived), and sort by newest, oldest, A–Z, Z–A, or shuffle.
- **Theme & layout** — Light/dark themes, accent colors (monochrome, blue, amber, green), and card density presets (compact, cozy, spacious).
- **Persistent storage** — SQLite database for cards, translations, audio blobs, and settings. Pending cards retry automatically on next launch.
- **Configurable API** — Base URL via `--dart-define=API_BASE_URL=...`, API key stored in settings.

## Screenshots

<!-- TODO: add screenshots -->

## Requirements

- **Flutter** ≥ 3.12
- A companion server that exposes these endpoints at the configured URL:

  ```
  POST /translate   { text, from, to } → { text }
  POST /tts         { text, language } → audio/mpeg
  ```

  Both endpoints accept an optional `x-api-key` header.

## Getting started

```bash
# Clone and install dependencies
flutter pub get

# Run with a custom API server (defaults to http://localhost:8787)
flutter run --dart-define=API_BASE_URL=http://your-server:8787
```

### Debug vs release builds

Debug builds use a `.debug` application ID suffix so they can coexist with the release build on the same device.

```bash
# Debug (installs as com.example.lang_app.debug on Android)
flutter run

# Release
flutter run --release
```

## Architecture

```
lib/
  config.dart                   # API base URL (dart-define)
  main.dart                     # Entry point, DI setup
  app.dart                      # Root widget

  models/                       # Data classes
  services/                     # SQLite, HTTP client, audio player
  repositories/                 # Business logic (cards, settings)
  viewmodels/                   # ChangeNotifier state holders
  widgets/                      # UI components
  utils/                        # Theme, time helpers
```

## License

MIT
