import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<void> _completeController = StreamController<void>.broadcast();
  final StreamController<void> _errorController = StreamController<void>.broadcast();
  StreamSubscription<AudioEvent>? _eventSub;

  AudioService() {
    _eventSub = _player.eventStream.listen(
      (event) {
        if (event.eventType == AudioEventType.complete) {
          _completeController.add(null);
        }
      },
      onError: (_) {
        _errorController.add(null);
      },
    );
  }

  Stream<void> get onComplete => _completeController.stream;
  Stream<void> get onPlaybackError => _errorController.stream;

  Future<void> playBytes(Uint8List bytes) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {
      _errorController.add(null);
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _eventSub?.cancel();
    _completeController.close();
    _errorController.close();
    _player.dispose();
  }
}
