import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../data/mock_jobs_repository.dart';
import '../data/pending_jobs_repository.dart';
import '../../profile/application/profile_providers.dart';
import '../domain/job.dart';
import '../domain/jobs_repository.dart';

final jobsRepositoryProvider = Provider<JobsRepository>((ref) {
  if (useMockData) {
    final repo = MockJobsRepository(ref.watch(sharedPreferencesProvider));
    ref.onDispose(repo.dispose);
    return repo;
  }
  final online = ref.watch(
    workerProfileProvider.select(
      (profile) => profile.asData?.value?.isAvailable ?? false,
    ),
  );
  final repo = PendingJobsRepository(initiallyOnline: online);
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
