import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Short UI sounds (the booking-confirmed chime). Behind a provider so
/// widget tests, which have no audio plugin, swap in [SilentSoundService]
/// instead of the screen guessing whether it is under test.
abstract class SoundService {
  Future<void> playSuccess();
  void dispose();
}

class AudioSoundService implements SoundService {
  AudioPlayer? _player;

  @override
  Future<void> playSuccess() async {
    try {
      _player ??= AudioPlayer();
      await _player!.play(AssetSource('success.wav'));
    } catch (_) {
      // The chime is decoration; a missing codec or device must never
      // break the confirmation screen.
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}

class SilentSoundService implements SoundService {
  @override
  Future<void> playSuccess() async {}

  @override
  void dispose() {}
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AudioSoundService();
  ref.onDispose(service.dispose);
  return service;
});
