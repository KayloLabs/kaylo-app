import 'feedback_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The short sounds the app can make. Each is a small WAV in the app's
/// `assets/` folder; `tool/make_sounds.py` in the customer app builds them.
enum KayloSound {
  success('success.wav'),

  /// The logo arriving on the hidden "made with care" page.
  logoChime('logo_chime.wav'),

  /// Five notes of a scale, one per tap on the logo.
  note1('note_1.wav'),
  note2('note_2.wav'),
  note3('note_3.wav'),
  note4('note_4.wav'),
  note5('note_5.wav'),

  /// A coupon being stamped onto a booking.
  coupon('coupon.wav'),

  /// A scratch reward opening.
  reveal('reveal.wav');

  final String asset;
  const KayloSound(this.asset);

  static const notes = [note1, note2, note3, note4, note5];
}

/// Short UI sounds (the booking-confirmed chime, a coupon stamp). Behind a
/// provider so widget tests, which have no audio plugin, swap in
/// [SilentSoundService] instead of the screen guessing whether it is
/// under test.
abstract class SoundService {
  Future<void> play(KayloSound sound);
  Future<void> playSuccess();
  void dispose();
}

class AudioSoundService implements SoundService {
  // A few players in turn, so a new note does not cut off the one still
  // ringing.
  final List<AudioPlayer> _players = [];
  int _next = 0;
  static const _voices = 3;

  @override
  Future<void> play(KayloSound sound) async {
    if (!KayloFeedback.soundsEnabled) return;
    try {
      if (_players.length < _voices) _players.add(AudioPlayer());
      final player = _players[_next++ % _players.length];
      await player.stop();
      await player.play(AssetSource(sound.asset));
    } catch (_) {
      // Sound is decoration; a missing codec or device must never break
      // the screen that asked for it.
    }
  }

  @override
  Future<void> playSuccess() => play(KayloSound.success);

  @override
  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    _players.clear();
  }
}

class SilentSoundService implements SoundService {
  /// What was asked for, so a test can check a sound was meant to play.
  final List<KayloSound> played = [];

  @override
  Future<void> play(KayloSound sound) async => played.add(sound);

  @override
  Future<void> playSuccess() => play(KayloSound.success);

  @override
  void dispose() {}
}

final soundServiceProvider = Provider<SoundService>((ref) {
  final service = AudioSoundService();
  ref.onDispose(service.dispose);
  return service;
});
