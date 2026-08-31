import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around the platform speech recogniser (the device or
/// browser engine; there is no in-app model).
///
/// Every failure mode is surfaced: [onError] and [onStatus] are mutable
/// so each listening session can attach its own handlers, and callers
/// must treat `init() == false` or an error callback as a normal
/// outcome, never a hang.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _ready = false;

  /// Session handlers, replaced by whichever UI is currently listening.
  void Function(String error, bool permanent)? onError;
  void Function(String status)? onStatus;

  Future<bool> init() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onError: (e) => onError?.call(e.errorMsg, e.permanent),
        onStatus: (s) => onStatus?.call(s),
      );
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// Best recogniser locale for an app language code ('en', 'ml', 'hi',
  /// 'ta'). Prefers the Indian variant, then any variant, then null
  /// (device default).
  Future<String?> localeFor(String languageCode) async {
    try {
      final locales = await _speech.locales();
      final want = languageCode.toLowerCase();
      String? fallback;
      for (final locale in locales) {
        final id = locale.localeId.toLowerCase().replaceAll('-', '_');
        if (id.startsWith('${want}_in')) return locale.localeId;
        if (id == want || id.startsWith('${want}_')) {
          fallback ??= locale.localeId;
        }
      }
      return fallback;
    } catch (_) {
      return null;
    }
  }

  Future<void> listen({
    required String? localeId,
    required void Function(String words, bool isFinal) onResult,
  }) {
    return _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
      ),
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
    );
  }

  bool get isListening => _speech.isListening;

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();

  /// True for errors the user must fix outside the app (permissions).
  static bool isPermissionError(String error) {
    final e = error.toLowerCase();
    return e.contains('not-allowed') ||
        e.contains('permission') ||
        e.contains('denied') ||
        e.contains('insufficient');
  }
}

final speechServiceProvider = Provider<SpeechService>((ref) => SpeechService());
