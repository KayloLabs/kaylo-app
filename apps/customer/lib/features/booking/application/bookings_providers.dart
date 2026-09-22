import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/models/booking.dart';
import '../../../core/models/worker.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/supabase_providers.dart';
import '../../../core/services/payment_service.dart';
import '../../auth/application/current_user_provider.dart';
import '../../workers/application/workers_providers.dart';
import '../data/mock_bookings_repository.dart';
import '../data/supabase_bookings_repository.dart';
import '../domain/bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  if (useMockData) {
    return MockBookingsRepository();
  }
  return SupabaseBookingsRepository(ref.watch(supabaseClientProvider));
});

/// Payment gateway. The stub approves everything; M4 swaps in Razorpay
/// here without touching any checkout screen.
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentServiceStub();
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
