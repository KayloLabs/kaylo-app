import '../../../core/models/booking.dart';
import '../domain/bookings_repository.dart';

class MockBookingsRepository implements BookingsRepository {
  // Seed history so personalized recommendations are demoable offline.
  final List<Booking> _mockBookings = [
    Booking(
      id: 'b1',
      userId: 'mock_uid_1',
      serviceId: '1', // Coconut Plucking
      workerId: 'w1',
      scheduledAt: DateTime(2026, 7, 14, 9),
      status: BookingStatus.completed,
      totalAmount: 1000,
      notes: 'Thekkedath House, Kaloor',
    ),
    Booking(
      id: 'b2',
      userId: 'mock_uid_1',
      serviceId: '1', // Coconut Plucking again
      workerId: 'w2',
      scheduledAt: DateTime(2026, 8, 2, 10),
      status: BookingStatus.completed,
      totalAmount: 1000,
      notes: 'Thekkedath House, Kaloor',
    ),
    // Always a few days ahead, so the demo (and the details screen's
    // reschedule and cancel actions) never age into the past.
    Booking(
      id: 'b3',
      userId: 'mock_uid_1',
      serviceId: '4', // Plumbing
      workerId: 'w2',
      scheduledAt: _daysFromNow(3, hour: 15),
      status: BookingStatus.confirmed,
      totalAmount: 500,
      notes: 'Thekkedath House, Kaloor',
    ),
  ];

  static DateTime _daysFromNow(int days, {required int hour}) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + days, hour);
  }

  // The demo has a single customer, and the mock auth layer hands out a
  // couple of different ids for them (fresh OTP login vs restored
  // session), so the filter is deliberately not applied here.
  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return List.unmodifiable(_mockBookings);
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newBooking = Booking(
      id: 'KL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      userId: booking.userId,
      serviceId: booking.serviceId,
      workerId: booking.workerId,
      scheduledAt: booking.scheduledAt,
      status: booking.status,
      totalAmount: booking.totalAmount,
      locationId: booking.locationId,
      notes: booking.notes,
    );
    _mockBookings.add(newBooking);
    return newBooking;
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _replace(bookingId, (old) => _copy(old, status: status));
  }

  @override
  Future<void> rescheduleBooking(String bookingId, DateTime scheduledAt) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _replace(bookingId, (old) => _copy(old, scheduledAt: scheduledAt));
  }

  void _replace(String bookingId, Booking Function(Booking old) update) {
    final index = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) _mockBookings[index] = update(_mockBookings[index]);
  }

  Booking _copy(Booking old, {BookingStatus? status, DateTime? scheduledAt}) {
    return Booking(
      id: old.id,
      userId: old.userId,
      serviceId: old.serviceId,
      workerId: old.workerId,
      scheduledAt: scheduledAt ?? old.scheduledAt,
      status: status ?? old.status,
      totalAmount: old.totalAmount,
      locationId: old.locationId,
      notes: old.notes,
      finalCost: old.finalCost,
    );
  }
}
