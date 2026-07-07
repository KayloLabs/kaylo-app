import '../../../core/models/booking.dart';
import '../domain/bookings_repository.dart';

class MockBookingsRepository implements BookingsRepository {
  final List<Booking> _mockBookings = [];

  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _mockBookings.where((b) => b.userId == userId).toList();
  }

  @override
  Future<Booking> createBooking(Booking booking) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final newBooking = Booking(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: booking.userId,
      serviceId: booking.serviceId,
      workerId: booking.workerId,
      scheduledAt: booking.scheduledAt,
      status: booking.status,
      totalAmount: booking.totalAmount,
    );
    _mockBookings.add(newBooking);
    return newBooking;
  }

  @override
  Future<void> updateBookingStatus(String bookingId, BookingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _mockBookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _mockBookings[index];
      _mockBookings[index] = Booking(
        id: old.id,
        userId: old.userId,
        serviceId: old.serviceId,
        workerId: old.workerId,
        scheduledAt: old.scheduledAt,
        status: status,
        totalAmount: old.totalAmount,
      );
    }
  }
}
