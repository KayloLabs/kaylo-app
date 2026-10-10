import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../../jobs/application/jobs_providers.dart';
import '../../jobs/domain/jobs_repository.dart';
import '../data/mock_worker_profile_repository.dart';
import '../data/supabase_worker_profile_repository.dart';
import '../domain/worker_profile.dart';

/// The sample worker for demos and tests; the worker's own row through
/// Supabase when the live build has a Firebase session to sign the
/// requests with (the same rule as the sign-in repository).
final workerProfileRepositoryProvider = Provider<WorkerProfileRepository>((
  ref,
) {
  final WorkerProfileRepository repo = useMockData || !FirebaseBootstrap.isReady
      ? MockWorkerProfileRepository(ref.watch(sharedPreferencesProvider))
      : SupabaseWorkerProfileRepository(ref.watch(supabaseClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// The signed-in worker; null until they finish registration.
final workerProfileProvider = StreamProvider<WorkerProfile?>((ref) {
  return ref.watch(workerProfileRepositoryProvider).watchProfile();
});

final serviceOptionsProvider = FutureProvider<List<ServiceOption>>((ref) {
  return ref.watch(workerProfileRepositoryProvider).listServices();
});

/// The on-duty switch. The jobs feed (what the screen shows) and the
/// worker's row (`is_available`, what customers see) move together; when
/// the row cannot be written the feed goes back, so the two never differ.
final dutySwitchProvider = Provider<DutySwitch>((ref) {
  return DutySwitch(
    jobs: ref.watch(jobsRepositoryProvider),
    profile: ref.watch(workerProfileRepositoryProvider),
  );
});

class DutySwitch {
  final JobsRepository jobs;
  final WorkerProfileRepository profile;

  const DutySwitch({required this.jobs, required this.profile});

  Future<void> set(bool online) async {
    await jobs.setDuty(online);
    try {
      await profile.setAvailable(online);
    } catch (e) {
      await jobs.setDuty(!online);
      rethrow;
    }
  }
}
