import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> playBytes(Uint8List bytes) async {
    await _player.stop();
    await _player.play(BytesSource(bytes));
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Stream<void> get onComplete => _player.onPlayerComplete;

  void dispose() {
    _player.dispose();
  }
}
