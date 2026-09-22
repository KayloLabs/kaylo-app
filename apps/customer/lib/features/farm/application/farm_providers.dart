import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/network/app_failure.dart';
import '../../auth/application/current_user_provider.dart';
import '../../booking/application/bookings_providers.dart';
import '../../booking/domain/payment_method.dart';
import '../../home/application/home_providers.dart';
import '../../workers/application/workers_providers.dart';
import '../domain/farm_booking_draft.dart';

/// Every farm service in the catalog.
final farmServicesProvider = FutureProvider.autoDispose<List<ServiceItem>>((
  ref,
) {
  return ref.watch(homeRepositoryProvider).getServicesByCategory('farm');
});

/// One service by id for the checkout screens. Reads the whole catalog,
/// not just farm, because the home flow books through the same schedule
/// and payment steps. Throws on an unknown id so a bad deep link
/// surfaces as an error state instead of a blank screen.
final farmServiceProvider = FutureProvider.autoDispose
    .family<ServiceItem, String>((ref, id) async {
      final services = await ref.watch(fullCatalogProvider.future);
      return services.firstWhere(
        (s) => s.id == id,
        orElse: () =>
            throw ServerFailure('Service not found', code: 'not-found'),
      );
    });

/// Workers who offer a service, for the availability line and rating.
final farmWorkersProvider = FutureProvider.autoDispose
    .family<List<Worker>, String>((ref, serviceId) {
      return ref
          .watch(workersRepositoryProvider)
          .getWorkersByServiceId(serviceId);
    });

/// Rating summary across the workers offering a service; null when none
/// have reviews yet, so the UI never invents a number.
({double rating, int reviews})? ratingSummary(List<Worker> workers) {
  final rated = workers.where((w) => w.reviewsCount > 0).toList();
  if (rated.isEmpty) return null;
  final reviews = rated.fold<int>(0, (sum, w) => sum + w.reviewsCount);
  final weighted = rated.fold<double>(
    0,
    (sum, w) => sum + w.rating * w.reviewsCount,
  );
  return (rating: weighted / reviews, reviews: reviews);
}

final farmCheckoutControllerProvider =
    AsyncNotifierProvider.autoDispose<FarmCheckoutController, Booking?>(
      FarmCheckoutController.new,
    );

/// Runs the payment gateway (unless paying after the service) and then
/// records the booking. State carries the created booking, or the error
/// for the payment screen to surface.
class FarmCheckoutController extends AsyncNotifier<Booking?> {
  @override
  Future<Booking?> build() async => null;

  Future<Booking?> confirm({
    required FarmBookingDraft draft,
    required PaymentMethod method,
  }) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      state = AsyncError(
        ServerFailure('Sign in to book a service', code: 'unauthenticated'),
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncLoading();
    final result = await AsyncValue.guard(() async {
      if (method != PaymentMethod.payAfterService) {
        final payments = ref.read(paymentServiceProvider);
        final initialized = await payments.initializePayment(
          amount: draft.total.toStringAsFixed(2),
          orderId:
              '${draft.service.category}-${draft.service.id}-${draft.scheduledAt.millisecondsSinceEpoch}',
          currency: 'INR',
        );
        final paid = initialized && await payments.processPayment();
        if (!paid) {
          throw ServerFailure('Payment was not completed', code: 'payment');
        }
      }

      return ref
          .read(bookingsRepositoryProvider)
          .createBooking(
            Booking(
              id: '',
              userId: userId,
              serviceId: draft.service.id,
              workerId: draft.workerId,
              scheduledAt: draft.scheduledAt,
              status: method == PaymentMethod.payAfterService
                  ? BookingStatus.pending
                  : BookingStatus.confirmed,
              totalAmount: draft.total,
              notes: draft.address,
            ),
          );
    });

    state = result;
    final booking = result.whenOrNull(data: (b) => b);
    if (booking != null) ref.invalidate(userBookingsProvider);
    return booking;
  }
}
