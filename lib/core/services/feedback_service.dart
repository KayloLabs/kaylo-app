import 'package:flutter/services.dart';

/// Centralised tactile and audible feedback for the whole app.
///
/// Three tiers, matched to the weight of the action:
///  - [tap]    light tick for selections (tabs, toggles, list rows)
///  - [press]  firmer thump for primary actions (buttons, confirmations)
///  - [alert]  strong pulse reserved for critical actions (SOS)
///
/// Every call is safe on every platform: haptics and system sounds
/// quietly no-op where unsupported (web, desktop), so callers never
/// need to guard.
class KayloFeedback {
  KayloFeedback._();

  static void tap() {
    HapticFeedback.selectionClick();
    SystemSound.play(SystemSoundType.click);
  }

  static void press() {
    HapticFeedback.lightImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void alert() {
    HapticFeedback.heavyImpact();
  }
}
