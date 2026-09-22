import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/storage_service.dart';

/// The in-app star rating the customer gave (1 to 5), null until they do.
/// Kept locally; there is no store listing to hand off to yet.
final appRatingProvider = NotifierProvider<AppRatingNotifier, int?>(
  AppRatingNotifier.new,
);

class AppRatingNotifier extends Notifier<int?> {
  @override
  int? build() {
    try {
      return ref.read(sharedPreferencesProvider).getInt('app_rating');
    } catch (_) {
      return null; // widget tests run without SharedPreferences
    }
  }

  Future<void> rate(int stars) async {
    state = stars;
    await ref.read(storageServiceProvider).saveAppRating(stars);
  }
}
