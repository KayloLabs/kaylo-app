import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

/// Persistent Care Mode flag. The full `careTheme` shell arrives in R2;
/// for now this drives the toggle in Settings and the dashboard switcher.
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
