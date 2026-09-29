import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/network/app_failure.dart';
import '../../auth/application/current_user_provider.dart';
import '../domain/booking_draft.dart';
import '../domain/payment_method.dart';
import 'bookings_providers.dart';

final bookingCheckoutControllerProvider =
    AsyncNotifierProvider.autoDispose<BookingCheckoutController, Booking?>(
  BookingCheckoutController.new,
);

/// Finds a specific booking from the user's booking history by ID.
final bookingByIdProvider =
    Provider.autoDispose.family<Booking?, String>((ref, bookingId) {
  final bookingsAsync = ref.watch(userBookingsProvider);
  return bookingsAsync.whenOrNull(
    data: (list) => list.where((b) => b.id == bookingId).firstOrNull,
  );
});

/// Generic booking controller handling service checkout, payments, and status transitions.
class BookingCheckoutController extends AsyncNotifier<Booking?> {
  @override
  Future<Booking?> build() async => null;

  /// Confirms a booking with the chosen payment method.
  Future<Booking?> confirm({
    required BookingDraft draft,
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
      // If paying via UPI or Card, invoke the payment service gateway
      if (method != PaymentMethod.payAfterService) {
        final payments = ref.read(paymentServiceProvider);
        final initialized = await payments.initializePayment(
          amount: draft.total.toStringAsFixed(2),
          orderId: 'kaylo-${draft.service.id}-${draft.scheduledAt.millisecondsSinceEpoch}',
          currency: 'INR',
        );
        final paid = initialized && await payments.processPayment();
        if (!paid) {
          throw ServerFailure('Payment was not completed', code: 'payment');
        }
      }

      final combinedNotes = draft.notes.trim().isNotEmpty
          ? '${draft.address} • Notes: ${draft.notes.trim()}'
          : draft.address;

      return ref.read(bookingsRepositoryProvider).createBooking(
            Booking(
              id: '',
              userId: userId,
              serviceId: draft.service.id,
              workerId: draft.worker?.id,
              scheduledAt: draft.scheduledAt,
              status: method == PaymentMethod.payAfterService
                  ? BookingStatus.pending
                  : BookingStatus.confirmed,
              totalAmount: draft.total,
              notes: combinedNotes,
            ),
          );
    });

    state = result;
    final booking = result.whenOrNull(data: (b) => b);
    if (booking != null) {
      ref.invalidate(userBookingsProvider);
    }
    return booking;
  }

  /// Updates booking status (used by the Review 1 live tracking simulator).
  Future<void> updateStatus(String bookingId, BookingStatus newStatus) async {
    await ref
        .read(bookingsRepositoryProvider)
        .updateBookingStatus(bookingId, newStatus);
    ref.invalidate(userBookingsProvider);
  }
}
