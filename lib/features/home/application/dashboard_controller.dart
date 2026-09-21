import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/service_item.dart';
import '../../auth/application/current_user_provider.dart';
import 'home_providers.dart';
import 'user_location_provider.dart';

class DashboardState {
  final String userName;
  final String location;
  final List<ServiceItem> popularServices;

  DashboardState({
    required this.userName,
    required this.location,
    required this.popularServices,
  });
}

final dashboardControllerProvider = FutureProvider.autoDispose<DashboardState>((
  ref,
) async {
  final repo = ref.watch(homeRepositoryProvider);

  final services = await repo.getPopularServices();
  final user = ref.watch(currentUserProvider);

  return DashboardState(
    userName: user?.firstName ?? '',
    location: ref.watch(userLocationProvider).label,
    popularServices: services,
  );
});
