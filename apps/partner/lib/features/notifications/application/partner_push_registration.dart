import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_core/services/device_tokens.dart';
import 'package:kaylo_core/services/notification_service.dart';
import '../../auth/application/partner_session.dart';
import '../../auth/domain/partner_auth_repository.dart';
import '../../profile/application/profile_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/partner_push_service.dart';

final partnerPushRegistrationProvider = Provider<void>((ref) {
  if (useMockData || !FirebaseBootstrap.isReady) return;
  final access = ref.watch(partnerAuthStateProvider).asData?.value;
  if (access?.status != PartnerAccessStatus.ready) return;
  final profile = ref.watch(workerProfileProvider).asData?.value;
  if (profile == null) return;
  final service = ref.watch(notificationServiceProvider);
  final registrar = DeviceTokenRegistrar(ref.watch(supabaseClientProvider));
  final locale = ref.watch(partnerLocaleProvider);
  final l10n = lookupAppLocalizations(locale);
  final plugin = FlutterLocalNotificationsPlugin();
  Future<void>? initialized;
  final native =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  Future<void> initializeLocal() => initialized ??= plugin
      .initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final id = response.payload;
          if (id == null || !ref.mounted) return;
          final current = ref.read(partnerAuthStateProvider).asData?.value;
          if (current?.status == PartnerAccessStatus.ready) {
            ref.read(partnerRouterProvider).push(Routes.jobDetail(id));
          }
        },
      )
      .then((_) {});
  final binding = PartnerPushBinding(
    service: service,
    register: (token) => registrar.register(
      personId: profile.personId,
      token: token,
      platform: service.platform,
      app: 'partner',
    ),
    unregister: registrar.unregister,
    onRequest: (message) async {
      // FCM handles iOS foreground notification payloads itself.
      if (!native ||
          !ref.mounted ||
          defaultTargetPlatform == TargetPlatform.iOS) {
        return;
      }
      await initializeLocal();
      if (!ref.mounted) return;
      final id = message.data['booking_id'] as String;
      await plugin.show(
        partnerRequestNotificationId(id),
        l10n.partnerNewJobRequest,
        l10n.partnerOpenJobRequest,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'kaylo_partner_jobs',
            l10n.partnerJobNotifications,
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
        ),
        payload: id,
      );
    },
  );
  unawaited(() async {
    try {
      if (native) {
        await initializeLocal();
        await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              AndroidNotificationChannel(
                'kaylo_partner_jobs',
                l10n.partnerJobNotifications,
                importance: Importance.high,
              ),
            );
      }
      if (ref.mounted) await setActivePartnerPushBinding(binding);
    } catch (_) {
      // Push permission/channel failures do not block the worker's session.
    }
  }());
  ref.onDispose(() => unawaited(binding.dispose()));
});
