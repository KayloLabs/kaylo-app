import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service_item.dart';
import '../../auth/application/current_user_provider.dart';
import '../../booking/application/bookings_providers.dart';
import 'home_providers.dart';

/// Services for the dashboard rail, ranked by the user's booking history:
/// a service they booked before scores highest, then services sharing a
/// category with past bookings, then general popularity. With no usable
/// history (fresh user, signed-out live session) it falls back to the
/// plain popular list and `personalized` stays false.
final recommendedServicesProvider = FutureProvider.autoDispose<
    ({List<ServiceItem> services, bool personalized})>((ref) async {
  final homeRepo = ref.watch(homeRepositoryProvider);
  final bookingsRepo = ref.watch(bookingsRepositoryProvider);

  final pool = await homeRepo.getPopularServices();

  final userId = ref.watch(currentUserIdProvider);
  List bookings;
  try {
    bookings = userId == null
        ? const []
        : await bookingsRepo.getUserBookings(userId);
  } catch (_) {
    bookings = const []; // e.g. RLS-scoped live query without a session
  }
  if (bookings.isEmpty) return (services: pool, personalized: false);

  final byId = {for (final s in pool) s.id: s};
  final bookedIds = <String, int>{};
  final bookedCategories = <String, int>{};
  for (final b in bookings) {
    bookedIds.update(b.serviceId as String, (c) => c + 1, ifAbsent: () => 1);
    final category = byId[b.serviceId]?.category;
    if (category != null) {
      bookedCategories.update(category, (c) => c + 1, ifAbsent: () => 1);
    }
  }

  int score(ServiceItem s) =>
      3 * (bookedIds[s.id] ?? 0) + (bookedCategories[s.category] ?? 0);

  if (!pool.any((s) => score(s) > 0)) {
    return (services: pool, personalized: false);
  }

  final ranked = [...pool]..sort((a, b) {
      final diff = score(b) - score(a);
      if (diff != 0) return diff;
      return a.name.compareTo(b.name);
    });
  return (services: ranked, personalized: true);
});
