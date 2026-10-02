import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  AudioPlayer? _player;
  final StreamController<void> _completeController = StreamController<void>.broadcast();
  final StreamController<void> _errorController = StreamController<void>.broadcast();
  StreamSubscription<AudioEvent>? _eventSub;

  AudioPlayer _ensurePlayer() {
    final existing = _player;
    if (existing != null) return existing;
    final player = AudioPlayer();
    _eventSub = player.eventStream.listen(
      (event) {
        if (event.eventType == AudioEventType.complete) {
          _completeController.add(null);
        }
      },
      onError: (_) {
        _errorController.add(null);
      },
    );
    _player = player;
    return player;
  }

  Stream<void> get onComplete => _completeController.stream;
  Stream<void> get onPlaybackError => _errorController.stream;

  Future<void> playBytes(Uint8List bytes) async {
    try {
      final player = _ensurePlayer();
      await player.stop();
      await player.play(BytesSource(bytes));
    } catch (_) {
      _errorController.add(null);
    }
  }

  Future<void> stop() async {
    await _player?.stop();
  }

  void dispose() {
    _eventSub?.cancel();
    _completeController.close();
    _errorController.close();
    _player?.dispose();
  }
}
