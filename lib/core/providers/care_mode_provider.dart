import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Persistent Care Mode flag. When on, KayloApp swaps the entire app
/// into `AppTheme.careTheme` (18sp minimum text, 56x56 targets, always
/// light); the Settings theme selector is overridden while active.
class CareModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    _load();
    return false;
  }

  Future<void> _load() async {
    state = await ref.read(storageServiceProvider).getCareMode();
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await ref.read(storageServiceProvider).setCareMode(enabled);
  }
}

final careModeProvider = NotifierProvider<CareModeNotifier, bool>(
  CareModeNotifier.new,
);
