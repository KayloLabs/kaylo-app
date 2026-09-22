import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../data/mock_home_repository.dart';
import '../data/supabase_home_repository.dart';
import '../domain/home_repository.dart';

export 'package:kaylo_core/config/app_env.dart' show useMock, useMockData;

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  if (useMockData) {
    return MockHomeRepository();
  }
  return SupabaseHomeRepository(ref.watch(supabaseClientProvider));
});

/// The full service catalog, every category merged and deduped.
/// Voice search matches against this rather than the popular subset,
/// so non-popular services (caregivers, medicines, cleaning) are
/// findable by voice too.
final fullCatalogProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  final lists = await Future.wait([
    repo.getServicesByCategory('home'),
    repo.getServicesByCategory('farm'),
    repo.getServicesByCategory('care'),
  ]);
  final seen = <String>{};
  return [
    for (final list in lists)
      for (final service in list)
        if (seen.add(service.id)) service,
  ];
});

final serviceListProvider = FutureProvider.family<List<ServiceItem>, String>((
  ref,
  category,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getServicesByCategory(category);
});

final serviceDetailProvider = FutureProvider.family<ServiceItem?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getServiceById(id);
});

final popularServicesProvider = FutureProvider<List<ServiceItem>>((ref) async {
  final repo = ref.watch(homeRepositoryProvider);
  return repo.getPopularServices();
});
