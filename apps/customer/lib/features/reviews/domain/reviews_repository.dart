import 'booking_review.dart';

abstract class ReviewsRepository {
  /// The review this customer wrote for [bookingId], or null.
  Future<BookingReview?> getForBooking(String bookingId);

  /// Writes or rewrites the review for a completed booking.
  Future<BookingReview> submit({
    required String bookingId,
    required String workerId,
    required int rating,
    String? text,
    bool hideName = false,
  });
}
