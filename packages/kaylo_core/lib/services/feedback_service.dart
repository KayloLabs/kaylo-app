import 'dart:async';
import 'package:flutter/services.dart';

/// Small, intentional feedback. Drag detents stay silent; completed actions
/// use sound. Preferences are configured by each app at startup.
class KayloFeedback {
  KayloFeedback._();
  static bool hapticsEnabled = true;
  static bool soundsEnabled = true;
  static DateTime? _lastSelection;
  static void _safe(Future<void> task) =>
      unawaited(task.catchError((Object _) {}));
  static void selection() {
    final now = DateTime.now();
    if (_lastSelection != null &&
        now.difference(_lastSelection!).inMilliseconds < 45) {
      return;
    }
    _lastSelection = now;
    if (hapticsEnabled) _safe(HapticFeedback.selectionClick());
  }

  static void tap() {
    selection();
  }

  static void press() {
    if (hapticsEnabled) _safe(HapticFeedback.lightImpact());
    if (soundsEnabled) _safe(SystemSound.play(SystemSoundType.click));
  }

  static void success() {
    if (hapticsEnabled) _safe(HapticFeedback.mediumImpact());
  }

  static void alert() {
    if (hapticsEnabled) _safe(HapticFeedback.heavyImpact());
  }
}
