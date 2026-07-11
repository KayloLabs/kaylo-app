import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/service_item.dart';
import 'home_providers.dart';

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

  // Fetch popular services
  final services = await repo.getPopularServices();

  // Mocking M2's user data for R1
  return DashboardState(
    userName: 'Nimal',
    location: 'Kannur, Kerala',
    popularServices: services,
  );
});
