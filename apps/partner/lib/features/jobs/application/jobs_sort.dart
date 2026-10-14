import 'partner_location.dart';
import '../domain/geo.dart' as geo;
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

String serviceFilterKey(String value) {
  final key = value.trim().toLowerCase();
  return switch (key) {
    'appliance' => 'appliances',
    _ => key,
  };
}

String jobServiceKey(Job job) => serviceFilterKey(
  job.serviceIcon.isEmpty ? job.serviceName : job.serviceIcon,
);
bool jobMatchesServiceFilter(Job job, Set<String> selectedServices) =>
    selectedServices.isEmpty ||
    selectedServices.map(serviceFilterKey).contains(jobServiceKey(job));

List<Job> sortAndFilterJobs(
  List<Job> jobs, {
  JobSort sort = JobSort.nearest,
  Set<String> serviceFilters = const {},
}) {
  final filtered = jobs
      .where((j) => jobMatchesServiceFilter(j, serviceFilters))
      .toList();

  filtered.sort((a, b) {
    final order = switch (sort) {
      JobSort.nearest => (a.distanceKm ?? double.infinity).compareTo(
        b.distanceKm ?? double.infinity,
      ),
      JobSort.highestPayout => b.payout.compareTo(a.payout),
      JobSort.soonest => a.scheduledAt.compareTo(b.scheduledAt),
    };
    if (order != 0) return order;
    final time = a.scheduledAt.compareTo(b.scheduledAt);
    return time != 0 ? time : a.id.compareTo(b.id);
  });
  return filtered;
}

final sortedIncomingRequestsProvider = Provider<AsyncValue<List<Job>>>((ref) {
  final requestsAsync = ref.watch(incomingRequestsProvider);
  final sort = ref.watch(jobSortProvider);
  final position = ref.watch(partnerLocationProvider).asData?.value;
  final filters = ref.watch(jobServiceFilterProvider);

  return requestsAsync.whenData((requests) {
    return sortAndFilterJobs(
      [
        for (final job in requests)
          if (position != null && job.latitude != null && job.longitude != null)
            job.copyWith(
              distanceKm: geo.distanceKm(
                position.latitude,
                position.longitude,
                job.latitude!,
                job.longitude!,
              ),
            )
          else
            job,
      ],
      sort: sort,
      serviceFilters: filters,
    );
  });
});
