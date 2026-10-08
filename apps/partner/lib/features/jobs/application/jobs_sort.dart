import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../domain/job.dart';
import 'jobs_providers.dart';

enum JobSort {
  nearest,
  highestPayout,
  soonest;

  static JobSort fromString(String? value) {
    switch (value) {
      case 'highestPayout':
        return JobSort.highestPayout;
      case 'soonest':
        return JobSort.soonest;
      case 'nearest':
      default:
        return JobSort.nearest;
    }
  }
}

class JobSortNotifier extends Notifier<JobSort> {
  static const prefKey = 'partner.job_sort';

  @override
  JobSort build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(prefKey);
    return JobSort.fromString(saved);
  }

  void setSort(JobSort sort) {
    state = sort;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString(prefKey, sort.name);
  }
}

final jobSortProvider = NotifierProvider<JobSortNotifier, JobSort>(
  JobSortNotifier.new,
);

class JobServiceFilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const <String>{};

  void toggle(String service) {
    if (state.contains(service)) {
      state = {...state}..remove(service);
    } else {
      state = {...state, service};
    }
  }

  void clear() {
    state = const <String>{};
  }
}

final jobServiceFilterProvider =
    NotifierProvider<JobServiceFilterNotifier, Set<String>>(
  JobServiceFilterNotifier.new,
);

bool jobMatchesServiceFilter(Job job, Set<String> selectedServices) {
  if (selectedServices.isEmpty) return true;
  return selectedServices.any((filter) {
    final f = filter.toLowerCase().trim();
    final name = job.serviceName.toLowerCase().trim();
    final icon = job.serviceIcon.toLowerCase().trim();
    return name.contains(f) ||
        f.contains(name) ||
        icon.contains(f) ||
        f.contains(icon);
  });
}

List<Job> sortAndFilterJobs(
  List<Job> jobs, {
  JobSort sort = JobSort.nearest,
  Set<String> serviceFilters = const {},
}) {
  final filtered =
      jobs.where((j) => jobMatchesServiceFilter(j, serviceFilters)).toList();

  switch (sort) {
    case JobSort.nearest:
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      break;
    case JobSort.highestPayout:
      filtered.sort((a, b) => b.payout.compareTo(a.payout));
      break;
    case JobSort.soonest:
      filtered.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      break;
  }

  return filtered;
}

final sortedIncomingRequestsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final requestsAsync = ref.watch(incomingRequestsProvider);
  final sort = ref.watch(jobSortProvider);
  final filters = ref.watch(jobServiceFilterProvider);

  return requestsAsync.whenData((requests) {
    return sortAndFilterJobs(
      requests,
      sort: sort,
      serviceFilters: filters,
    );
  });
});
