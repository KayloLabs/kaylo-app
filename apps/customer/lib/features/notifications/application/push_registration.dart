import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_core/services/device_tokens.dart';
import 'package:kaylo_core/services/notification_service.dart';

import '../../auth/application/current_user_provider.dart';

/// Keeps this device's push token registered for whoever is signed in,
/// and re-registers when Firebase rotates it. Watch it once from the app
/// root; it does nothing in mock mode or without Firebase.
final pushRegistrationProvider = Provider<void>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null || useMockData || !FirebaseBootstrap.isReady) return;

  final service = ref.watch(notificationServiceProvider);
  final registrar = DeviceTokenRegistrar(ref.watch(supabaseClientProvider));

  Future<void> register(String? token) async {
    if (token == null) return;
    try {
      await registrar.register(
        personId: user.id,
        token: token,
        platform: service.platform,
        app: 'customer',
      );
    } catch (_) {
      // Push is best effort; a failed registration must never surface.
    }
  }

  service.initialize().then((_) => service.getToken()).then(register);
  final subscription = service.onTokenRefresh.listen(register);
  ref.onDispose(subscription.cancel);
});
