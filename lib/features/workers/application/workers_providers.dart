import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/models/worker.dart';
import '../../../core/network/supabase_providers.dart';
import '../data/mock_workers_repository.dart';
import '../data/supabase_workers_repository.dart';
import '../domain/models/worker_filter.dart';
import '../domain/models/worker_review.dart';
import '../domain/workers_repository.dart';

export '../domain/models/worker_filter.dart';
export '../domain/models/worker_review.dart';

final workersRepositoryProvider = Provider<WorkersRepository>((ref) {
  if (useMockData) {
    return MockWorkersRepository();
  }
  return SupabaseWorkersRepository(ref.watch(supabaseClientProvider));
});

final workerListProvider = FutureProvider.family<List<Worker>, String>((
  ref,
  serviceId,
) async {
  final repo = ref.watch(workersRepositoryProvider);
  return repo.getWorkersByServiceId(serviceId);
});

final workerDetailProvider = FutureProvider.family<Worker, String>((
  ref,
  workerId,
) async {
  final repo = ref.watch(workersRepositoryProvider);
  return repo.getWorkerById(workerId);
});

final workerReviewsProvider = FutureProvider.family<List<WorkerReview>, String>(
  (ref, workerId) async {
    final repo = ref.watch(workersRepositoryProvider);
    return repo.getReviewsForWorker(workerId);
  },
);

class WorkerFilterSortState {
  final WorkerSort sort;
  final WorkerFilter filter;

  const WorkerFilterSortState({
    this.sort = WorkerSort.rating,
    this.filter = const WorkerFilter(),
  });

  WorkerFilterSortState copyWith({WorkerSort? sort, WorkerFilter? filter}) {
    return WorkerFilterSortState(
      sort: sort ?? this.sort,
      filter: filter ?? this.filter,
    );
  }
}

class WorkerFilterSortNotifier extends Notifier<WorkerFilterSortState> {
  @override
  WorkerFilterSortState build() {
    return const WorkerFilterSortState();
  }

  void setSort(WorkerSort sort) {
    state = state.copyWith(sort: sort);
  }

  void updateFilter(WorkerFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void resetFilter() {
    state = state.copyWith(filter: const WorkerFilter());
  }

  void resetAll() {
    state = const WorkerFilterSortState();
  }
}

final workerFilterSortProvider =
    NotifierProvider<WorkerFilterSortNotifier, WorkerFilterSortState>(
      WorkerFilterSortNotifier.new,
    );

final filteredWorkersProvider = FutureProvider.family<List<Worker>, String>((
  ref,
  serviceId,
) async {
  final workers = await ref.watch(workerListProvider(serviceId).future);
  final filterSort = ref.watch(workerFilterSortProvider);
  final filter = filterSort.filter;
  final sort = filterSort.sort;

  var result = workers.where((w) {
    if (filter.minRating != null && w.rating < filter.minRating!) {
      return false;
    }
    if (filter.maxPrice != null && (w.hourlyRate ?? 0) > filter.maxPrice!) {
      return false;
    }
    if (filter.availableToday && !w.isAvailable) {
      return false;
    }
    if (filter.verifiedOnly && !w.isVerified) {
      return false;
    }
    return true;
  }).toList();

  switch (sort) {
    case WorkerSort.rating:
      result.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case WorkerSort.priceLowToHigh:
      result.sort((a, b) => (a.hourlyRate ?? 0).compareTo(b.hourlyRate ?? 0));
      break;
    case WorkerSort.priceHighToLow:
      result.sort((a, b) => (b.hourlyRate ?? 0).compareTo(a.hourlyRate ?? 0));
      break;
    case WorkerSort.experience:
      result.sort((a, b) => b.totalJobs.compareTo(a.totalJobs));
      break;
    case WorkerSort.distance:
      // In mock/district mode, stable order
      break;
  }

  return result;
});
