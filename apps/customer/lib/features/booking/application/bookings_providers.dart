import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../auth/application/current_user_provider.dart';
import '../../workers/application/workers_providers.dart';
import '../data/checkout/razorpay_checkout.dart';
import '../data/mock_bookings_repository.dart';
import '../data/mock_payment_gateway.dart';
import '../data/razorpay_gateway.dart';
import '../data/supabase_bookings_repository.dart';
import '../domain/bookings_repository.dart';
import '../domain/payment_gateway.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  if (useMockData) {
    return MockBookingsRepository();
  }
  return SupabaseBookingsRepository(ref.watch(supabaseClientProvider));
});

/// Payment gateway: Razorpay through our server functions, or a
/// stand-in that approves after a pause in the demo build.
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  if (useMockData) return MockPaymentGateway();
  return RazorpayGateway(
    ref.watch(supabaseClientProvider),
    createRazorpayCheckout(),
  );
});

/// The signed-in user's bookings, newest scheduled first. Invalidate it
/// after creating a booking so the Bookings tab picks the new row up.
final userBookingsProvider = FutureProvider.autoDispose<List<Booking>>((
  ref,
) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final bookings = await ref
      .watch(bookingsRepositoryProvider)
      .getUserBookings(userId);
  return [...bookings]..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
});

final bookingByIdProvider = FutureProvider.autoDispose.family<Booking, String>((
  ref,
  id,
) async {
  final bookings = await ref.watch(userBookingsProvider.future);
  return bookings.firstWhere(
    (b) => b.id == id,
    orElse: () => throw ServerFailure('Booking not found', code: 'not-found'),
  );
});

/// The worker assigned to a booking, for the details screen.
final bookingWorkerProvider = FutureProvider.autoDispose.family<Worker, String>(
  (ref, workerId) {
    return ref.watch(workersRepositoryProvider).getWorkerById(workerId);
  },
);

/// A worker and a day, the key for [takenSlotsProvider].
typedef WorkerDay = ({String workerId, DateTime date});

/// The slot start times (minutes) a worker already holds on a day. The
/// schedule and reschedule screens grey those slots out; the database
/// refuses them anyway if two people race.
final takenSlotsProvider = FutureProvider.autoDispose
    .family<Set<int>, WorkerDay>((ref, key) {
      final day = DateTime(key.date.year, key.date.month, key.date.day);
      return ref
          .watch(bookingsRepositoryProvider)
          .takenSlotMinutes(key.workerId, day);
    });

final bookingsControllerProvider = Provider<BookingsController>((ref) {
  return BookingsController(ref);
});

/// Changes to an existing booking; every write refreshes the list.
class BookingsController {
  final Ref _ref;

  BookingsController(this._ref);

  Future<void> cancel(String bookingId) async {
    await _ref
        .read(bookingsRepositoryProvider)
        .updateBookingStatus(bookingId, BookingStatus.cancelled);
    _ref.invalidate(userBookingsProvider);
  }

  Future<void> reschedule(String bookingId, DateTime scheduledAt) async {
    await _ref
        .read(bookingsRepositoryProvider)
        .rescheduleBooking(bookingId, scheduledAt);
    _ref.invalidate(userBookingsProvider);
  }
}
