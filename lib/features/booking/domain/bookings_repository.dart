import '../../../core/models/booking.dart';

abstract class BookingsRepository {
  Future<List<Booking>> getUserBookings(String userId);
  Future<Booking> createBooking(Booking booking);
  Future<void> updateBookingStatus(String bookingId, BookingStatus status);
}
