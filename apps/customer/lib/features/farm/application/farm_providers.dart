import '../../notifications/application/booking_reminders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/network/app_failure.dart';
import '../../auth/application/current_user_provider.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../booking/application/bookings_providers.dart';
import '../../booking/data/booking_emails.dart';
import '../../booking/domain/payment_choice.dart';
import '../../home/application/home_providers.dart';
import '../../workers/application/workers_providers.dart';
import '../domain/farm_booking_draft.dart';
import '../../offers/application/offers_providers.dart';

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

/// Records the booking, then takes the payment for it (unless paying
/// after the service). State carries the booking, or the error for the
/// payment screen to surface.
///
/// Online payment needs the booking first: the server reads the amount
/// from the row and ties the Razorpay order to it. A payment that does
/// not go through leaves the booking pending; a retry pays for that
/// same booking instead of creating another.
class FarmCheckoutController extends AsyncNotifier<Booking?> {
  Booking? _unpaid;
  bool _hasStartedPayment = false;

  /// An order can exist after a cancelled payment sheet, so keep its price.
  bool get hasStartedPayment => _hasStartedPayment;

  @override
  Future<Booking?> build() async => null;

  Future<Booking?> confirm({
    required FarmBookingDraft draft,
    required PaymentChoice method,
    String? email,
    String? offerCode,
    String? preferredMethod,
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
      final repo = ref.read(bookingsRepositoryProvider);
      Booking create() => Booking(
        id: '',
        userId: userId,
        serviceId: draft.service.id,
        workerId: draft.workerId,
        scheduledAt: draft.scheduledAt,
        status: BookingStatus.pending,
        totalAmount: draft.total,
        locationId: draft.locationId,
        notes: draft.bookingNotes,
      );

      Future<Booking> applyOffer(Booking created) async {
        try {
          return await ref.read(bookingOfferApplierProvider)(
            created,
            offerCode,
          );
        } catch (_) {
          // Release eligibility only before any gateway attempt. If cancelling
          // fails, retain the existing row so a retry cannot duplicate it.
          if (!_hasStartedPayment && created.status == BookingStatus.pending) {
            try {
              await repo.updateBookingStatus(
                created.id,
                BookingStatus.cancelled,
              );
              _unpaid = null;
              ref.invalidate(userBookingsProvider);
              ref.invalidate(offersProvider);
            } catch (_) {}
          }
          rethrow;
        }
      }

      if (method == PaymentChoice.payAfterService) {
        final created = _unpaid ?? await repo.createBooking(create());
        _unpaid = created;
        final booking = await applyOffer(created);
        _unpaid = null;
        // A note by email, when there is an address for it; the booking
        // stands either way.
        if (!useMockData && email != null && email.isNotEmpty) {
          await sendBookingReceivedEmail(
            ref.read(supabaseClientProvider),
            bookingId: booking.id,
            email: email,
          );
        }
        return booking;
      }

      final created = _unpaid ?? await repo.createBooking(create());
      _unpaid = created;
      final booking = await applyOffer(created);
      _unpaid = booking;
      _hasStartedPayment = true;
      final outcome = await ref
          .read(paymentGatewayProvider)
          .pay(
            bookingId: booking.id,
            email: email,
            preferredMethod: preferredMethod,
          );
      if (!outcome.paid) {
        throw ServerFailure(
          outcome.message ?? 'Payment was not completed',
          code: 'payment',
        );
      }
      _unpaid = null;
      // The server marks the row confirmed; the demo build has no
      // server, so the mock repository is told here.
      if (useMockData) {
        await repo.updateBookingStatus(booking.id, BookingStatus.confirmed);
      }
      return booking.copyWith(status: BookingStatus.confirmed);
    });

    state = result;
    final booking = result.whenOrNull(data: (b) => b);
    if (booking != null) {
      try {
        await ref
            .read(bookingRemindersProvider)
            .received(booking, draft.service.name);
      } catch (_) {
        /* Booking is already saved. */
      }
      ref.invalidate(userBookingsProvider);
      ref.invalidate(offersProvider);
    }
    return booking;
  }
}
