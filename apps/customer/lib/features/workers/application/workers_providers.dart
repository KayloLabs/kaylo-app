import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../data/mock_workers_repository.dart';
import '../data/supabase_workers_repository.dart';
import '../domain/models/worker_filter.dart';
import '../domain/models/worker_review.dart';
import '../domain/workers_repository.dart';
import '../../home/application/user_location_provider.dart';

export '../domain/models/worker_filter.dart';
export '../domain/models/worker_review.dart';

final workersRepositoryProvider = Provider<WorkersRepository>((ref) {
  if (useMockData) {
    return MockWorkersRepository();
  }
  return SupabaseWorkersRepository(ref.watch(supabaseClientProvider));
});

final workerListProvider = FutureProvider.autoDispose
    .family<List<Worker>, String>((ref, serviceId) async {
      final timer = Timer.periodic(
        const Duration(seconds: 15),
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(timer.cancel);
      final repo = ref.watch(workersRepositoryProvider);
      return repo.getWorkersByServiceId(serviceId);
    });

final workerDetailProvider = FutureProvider.autoDispose.family<Worker, String>((
  ref,
  workerId,
) async {
  final timer = Timer.periodic(
    const Duration(seconds: 15),
    (_) => ref.invalidateSelf(),
  );
  ref.onDispose(timer.cancel);
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

final filteredWorkersProvider = FutureProvider.autoDispose
    .family<List<Worker>, String>((ref, serviceId) async {
      final filterSort = ref.watch(workerFilterSortProvider);
      final location = filterSort.sort == WorkerSort.distance
          ? ref.watch(userLocationProvider)
          : null;
      final workers = await ref.watch(workerListProvider(serviceId).future);
      final filter = filterSort.filter;
      final sort = filterSort.sort;

      var result = workers.where((w) {
        if (filter.minRating != null && w.rating < filter.minRating!) {
          return false;
        }
        if (filter.maxPrice != null &&
            (w.hourlyRate == null || w.hourlyRate! > filter.maxPrice!)) {
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
          result.sort((a, b) => compareWorkerRates(a, b));
          break;
        case WorkerSort.priceHighToLow:
          result.sort((a, b) => compareWorkerRates(a, b, descending: true));
          break;
        case WorkerSort.experience:
          result.sort((a, b) => b.totalJobs.compareTo(a.totalJobs));
          break;
        case WorkerSort.distance:
          result.sort((a, b) {
            final nearby = localityScore(
              b.location,
              location!,
            ).compareTo(localityScore(a.location, location));
            return nearby != 0 ? nearby : b.rating.compareTo(a.rating);
          });
          break;
      }

      return result;
    });

/// Unknown hourly rates stay last, including descending order.
int compareWorkerRates(Worker a, Worker b, {bool descending = false}) {
  if (a.hourlyRate == null && b.hourlyRate != null) return 1;
  if (a.hourlyRate != null && b.hourlyRate == null) return -1;
  final order = descending
      ? (b.hourlyRate ?? 0).compareTo(a.hourlyRate ?? 0)
      : (a.hourlyRate ?? 0).compareTo(b.hourlyRate ?? 0);
  return order != 0 ? order : b.rating.compareTo(a.rating);
}

/// The current worker view exposes district names, not worker coordinates.
/// Rank shared localities without mistaking a saved label like "Home" or a
/// state shared by every worker for proximity. No kilometre claim is made.
int localityScore(String workerLocation, UserLocation active) {
  final ignored = {
    'home',
    'work',
    'farm',
    'kerala',
    'india',
    'road',
    'street',
    'district',
  };
  Set<String> tokens(String value) => value
      .toLowerCase()
      .split(RegExp(r'[^\p{L}\p{M}]+', unicode: true))
      .where((word) => word.length > 2 && !ignored.contains(word))
      .toSet();
  final workerTokens = tokens(workerLocation);
  final activeTokens = tokens('${active.addressLine ?? ''} ${active.label}');
  return workerTokens.intersection(activeTokens).length;
}
