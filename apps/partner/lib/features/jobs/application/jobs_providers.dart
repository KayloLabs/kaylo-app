import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_core/network/supabase_providers.dart';

import '../data/mock_jobs_repository.dart';
import '../data/pending_jobs_repository.dart';
import '../data/supabase_jobs_repository.dart';
import '../../auth/application/partner_session.dart';
import '../../profile/application/profile_providers.dart';
import '../domain/job.dart';
import '../domain/jobs_repository.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  if (useMockData) {
    final repo = MockJobsRepository(ref.watch(sharedPreferencesProvider));
    ref.onDispose(repo.dispose);
    return repo;
  }
  final online =
      ref.read(workerProfileProvider).asData?.value?.isAvailable ?? false;
  final workerId = ref.watch(partnerAuthStateProvider).asData?.value.workerId;
  final JobsRepository repo = workerId == null
      ? PendingJobsRepository(initiallyOnline: online)
      : SupabaseJobsRepository.live(
          ref.watch(supabaseClientProvider),
          workerId: workerId,
          initiallyOnline: online,
        );
  // Profile updates change the duty value, not the whole live feed. Recreating
  // the repository here used to duplicate the initial query and subscription.
  ref.listen(workerProfileProvider, (_, profile) {
    final available = profile.asData?.value?.isAvailable;
    if (available != null && available != repo.isOnline) {
      unawaited(repo.setDuty(available));
    }
  });
  ref.onDispose(repo.dispose);
  return repo;
});

final dutyStatusProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.watchDutyStatus();
});

final jobsStreamProvider = StreamProvider<List<Job>>((ref) {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.watchJobs();
});

final activeJobProvider = StreamProvider<Job?>((ref) {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.watchActiveJob();
});

final incomingRequestsProvider = StreamProvider<List<Job>>((ref) {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.watchIncomingRequests();
});

final jobHistoryProvider = StreamProvider<List<Job>>((ref) {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.watchHistory();
});

final jobDetailProvider = StreamProvider.family<Job?, String>((ref, id) {
  final repo = ref.watch(jobsRepositoryProvider);
  return repo.watchJobs().map((list) {
    try {
      return list.firstWhere((j) => j.id == id);
    } catch (_) {
      return null;
    }
  });
});
