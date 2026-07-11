import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/storage_service.dart';

enum SplashRouteDestination { onboarding, login, dashboard }

class SplashController extends AsyncNotifier<SplashRouteDestination?> {
  late StorageService _storageService;

  @override
  FutureOr<SplashRouteDestination?> build() {
    _storageService = ref.watch(storageServiceProvider);
    return null;
  }

  Future<void> initializeApp() async {
    state = const AsyncValue.loading();
    
    try {
      // Simulate Firebase/App initialization
      // TODO: await Firebase.initializeApp();
      await Future.delayed(const Duration(milliseconds: 300));

      final hasSeenOnboarding = false; // Forced to false for testing
      final token = await _storageService.getToken();

      if (!hasSeenOnboarding) {
        state = const AsyncValue.data(SplashRouteDestination.onboarding);
      } else if (token == null) {
        state = const AsyncValue.data(SplashRouteDestination.login);
      } else {
        state = const AsyncValue.data(SplashRouteDestination.dashboard);
      }
    } catch (e, stack) {
      // In case of error, default to login instead of hanging
      state = const AsyncValue.data(SplashRouteDestination.login);
    }
  }
}

final splashControllerProvider = AsyncNotifierProvider<SplashController, SplashRouteDestination?>(
  SplashController.new,
);
