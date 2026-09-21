import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service_item.dart';
import '../../../core/models/worker.dart';
import '../../../core/network/app_failure.dart';
import '../../home/application/home_providers.dart';
import '../../workers/application/workers_providers.dart';

/// Services of one category ('home', 'farm', 'care'), or the whole
/// catalog for 'all'.
final servicesByCategoryProvider =
    FutureProvider.autoDispose.family<List<ServiceItem>, String>((ref, category) {
  if (category == 'all') return ref.watch(fullCatalogProvider.future);
  return ref.watch(homeRepositoryProvider).getServicesByCategory(category);
});

/// One service by id from the full catalog; throws when the id is not
/// known so a bad deep link surfaces as an error state instead of a
/// blank screen.
final serviceByIdProvider =
    FutureProvider.autoDispose.family<ServiceItem, String>((ref, id) async {
  final services = await ref.watch(fullCatalogProvider.future);
  return services.firstWhere(
    (s) => s.id == id,
    orElse: () => throw ServerFailure('Service not found', code: 'not-found'),
  );
});

/// Workers who offer a service, for the availability line and rating.
final serviceWorkersProvider =
    FutureProvider.autoDispose.family<List<Worker>, String>((ref, serviceId) {
  return ref.watch(workersRepositoryProvider).getWorkersByServiceId(serviceId);
});

/// Rating summary across the workers offering a service; null when none
/// have reviews yet, so the UI never invents a number.
({double rating, int reviews})? ratingSummary(List<Worker> workers) {
  final rated = workers.where((w) => w.reviewsCount > 0).toList();
  if (rated.isEmpty) return null;
  final reviews = rated.fold<int>(0, (sum, w) => sum + w.reviewsCount);
  final weighted =
      rated.fold<double>(0, (sum, w) => sum + w.rating * w.reviewsCount);
  return (rating: weighted / reviews, reviews: reviews);
}
