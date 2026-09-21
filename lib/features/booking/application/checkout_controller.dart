import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/booking.dart';
import '../../../core/network/app_failure.dart';
import '../../auth/application/current_user_provider.dart';
import '../domain/booking_draft.dart';
import '../domain/payment_method.dart';
import 'bookings_providers.dart';

final checkoutControllerProvider =
    AsyncNotifierProvider.autoDispose<CheckoutController, Booking?>(
  CheckoutController.new,
);

/// Runs the payment gateway (unless paying after the service) and then
/// records the booking. State carries the created booking, or the error
/// for the payment screen to surface.
class CheckoutController extends AsyncNotifier<Booking?> {
  @override
  Future<Booking?> build() async => null;

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
      if (method != PaymentMethod.payAfterService) {
        final payments = ref.read(paymentServiceProvider);
        final initialized = await payments.initializePayment(
          amount: draft.total.toStringAsFixed(2),
          orderId:
              'svc-${draft.service.id}-${draft.scheduledAt.millisecondsSinceEpoch}',
          currency: 'INR',
        );
        final paid = initialized && await payments.processPayment();
        if (!paid) {
          throw ServerFailure('Payment was not completed', code: 'payment');
        }
      }

      return ref.read(bookingsRepositoryProvider).createBooking(
            Booking(
              id: '',
              userId: userId,
              serviceId: draft.service.id,
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
