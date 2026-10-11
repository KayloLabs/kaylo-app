import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_core/services/storage_service.dart';
import '../../auth/application/partner_session.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../data/mock_partner_notifications_repository.dart';
import '../data/supabase_partner_notifications_repository.dart';
import '../domain/partner_notification.dart';
import '../domain/partner_notifications_repository.dart';

final partnerAlertsRepositoryProvider =
    Provider<PartnerNotificationsRepository?>((ref) {
      final access = ref.watch(
        partnerAuthStateProvider.select(
          (s) => (s.asData?.value.workerId, s.asData?.value.status),
        ),
      );
      final personId = ref.watch(
        workerProfileProvider.select((p) => p.asData?.value?.personId),
      );
      final prefs = ref.watch(sharedPreferencesProvider);
      PartnerNotificationsRepository? repo;
      if (useMockData) {
        repo = MockPartnerNotificationsRepository(
          ref.watch(jobsRepositoryProvider),
          prefs,
          identity: access.$1 ?? 'demo',
        );
      } else if (personId != null) {
        repo = SupabasePartnerNotificationsRepository(
          ref.watch(supabaseClientProvider),
          personId: personId,
          prefs: prefs,
        );
      }
      ref.onDispose(() => repo?.dispose());
      return repo;
    });
final partnerAlertsProvider = StreamProvider<List<PartnerNotification>>(
  (ref) =>
      ref.watch(partnerAlertsRepositoryProvider)?.watchAll() ??
      const Stream.empty(),
);
final partnerAlertUnreadProvider = Provider<int>(
  (ref) =>
      ref
          .watch(partnerAlertsProvider)
          .asData
          ?.value
          .where((n) => !n.isRead)
          .length ??
      0,
);
