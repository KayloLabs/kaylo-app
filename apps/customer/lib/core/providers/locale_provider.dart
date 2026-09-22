import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // Load locale asynchronously but immediately return a default
    // so the UI can build without waiting.
    _loadLocale();
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    final storageService = ref.read(storageServiceProvider);
    final code = await storageService.getLanguageCode();
    if (code != null) {
      state = Locale(code);
    }
  }

  Future<void> setLocale(String languageCode) async {
    final storageService = ref.read(storageServiceProvider);
    await storageService.saveLanguageCode(languageCode);
    state = Locale(languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
