import 'dart:async';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final StreamController<void> _completeController = StreamController<void>.broadcast();

  AudioService() {
    _player.onPlayerComplete.listen((_) => _completeController.add(null));
  }

  Stream<void> get onComplete => _completeController.stream;

  Future<void> playBytes(Uint8List bytes) async {
    await _player.stop();
    await _player.play(BytesSource(bytes));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  void dispose() {
    _completeController.close();
    _player.dispose();
  }
}
