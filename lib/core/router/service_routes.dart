import 'package:go_router/go_router.dart';

import '../models/service_item.dart';
import 'routes.dart';

/// Opens the right screen for a catalog entry: farm services have their
/// own details flow, care lives in the Care tab, and everything else is
/// a home service. Takes the router rather than a context so callers
/// that pop themselves first (the voice overlay) can still navigate.
void openService(GoRouter router, ServiceItem service) {
  // "More" is a dashboard affordance, not a bookable service.
  if (service.basePrice <= 0) {
    router.push(Routes.homeServices);
    return;
  }
  switch (service.category) {
    case 'farm':
      router.push(Routes.farmService(service.id));
    case 'care':
      router.go(Routes.careHome);
    default:
      router.push('${Routes.serviceDetails}?id=${service.id}', extra: service);
  }
}
