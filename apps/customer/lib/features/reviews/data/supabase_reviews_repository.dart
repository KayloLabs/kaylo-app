import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/booking_review.dart';
import '../domain/reviews_repository.dart';

/// Reviews on the `reviews` table. Writing goes through `submit_review`,
/// which checks the booking is the caller's and completed, and refreshes the
/// worker's average by trigger.
class SupabaseReviewsRepository implements ReviewsRepository {
  final SupabaseClient _client;
  SupabaseReviewsRepository(this._client);

  @override
  Future<BookingReview?> getForBooking(String bookingId) async {
    try {
      final row = await _client
          .from('reviews')
          .select(
            'booking_id, worker_id, rating, review, hide_name, created_at',
          )
          .eq('booking_id', bookingId)
          .maybeSingle();
      if (row == null) return null;
      return BookingReview(
        bookingId: row['booking_id'] as String,
        workerId: row['worker_id'] as String,
        rating: (row['rating'] as num).toInt(),
        text: row['review'] as String?,
        hideName: row['hide_name'] as bool? ?? false,
        createdAt: DateTime.parse(row['created_at'] as String),
      );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<BookingReview> submit({
    required String bookingId,
    required String workerId,
    required int rating,
    String? text,
    bool hideName = false,
  }) async {
    try {
      await _client.rpc(
        'submit_review',
        params: {
          'p_booking_id': bookingId,
          'p_rating': rating,
          'p_review': text,
          'p_hide_name': hideName,
        },
      );
      return await getForBooking(bookingId) ??
          BookingReview(
            bookingId: bookingId,
            workerId: workerId,
            rating: rating,
            text: text,
            hideName: hideName,
            createdAt: DateTime.now(),
          );
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
