import 'package:kaylo_core/models/booking.dart';

abstract class BookingsRepository {
  Future<List<Booking>> getUserBookings(String userId);
  Future<Booking> createBooking(Booking booking);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
  Future<void> rescheduleBooking(String bookingId, DateTime scheduledAt);

  /// Start times (minutes from midnight) of the open bookings [workerId]
  /// already holds on [date], so the schedule can grey those slots out.
  Future<Set<int>> takenSlotMinutes(String workerId, DateTime date);
}
