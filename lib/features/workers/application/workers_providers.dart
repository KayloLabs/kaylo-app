import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/models/worker.dart';
import '../../../core/network/supabase_providers.dart';
import '../data/mock_workers_repository.dart';
import '../data/supabase_workers_repository.dart';
import '../domain/workers_repository.dart';

final workersRepositoryProvider = Provider<WorkersRepository>((ref) {
  if (useMockData) {
    return MockWorkersRepository();
  }
  return SupabaseWorkersRepository(ref.watch(supabaseClientProvider));
});

/// Workers qualified to deliver a specific service.
final workersByServiceProvider = FutureProvider.autoDispose
    .family<List<Worker>, String>((ref, serviceId) {
      return ref
          .watch(workersRepositoryProvider)
          .getWorkersByServiceId(serviceId);
    });

/// A worker assigned to a booking, used by the tracking screen.
final workerByIdProvider = FutureProvider.autoDispose.family<Worker, String>((
  ref,
  workerId,
) {
  return ref.watch(workersRepositoryProvider).getWorkerById(workerId);
});
