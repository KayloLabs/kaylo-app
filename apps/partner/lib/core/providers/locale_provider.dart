import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/storage_service.dart';

class PartnerLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
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

final partnerLocaleProvider =
    NotifierProvider<PartnerLocaleNotifier, Locale>(() {
  return PartnerLocaleNotifier();
});
