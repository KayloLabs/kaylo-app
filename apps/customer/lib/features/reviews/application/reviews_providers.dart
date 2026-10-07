import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../data/mock_reviews_repository.dart';
import '../data/supabase_reviews_repository.dart';
import '../domain/booking_review.dart';
import '../domain/reviews_repository.dart';

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  if (useMockData) {
    try {
      return MockReviewsRepository(ref.watch(sharedPreferencesProvider));
    } catch (_) {
      return MockReviewsRepository();
    }
  }
  return SupabaseReviewsRepository(ref.watch(supabaseClientProvider));
});

/// The customer's review of one booking, null until they write one.
final bookingReviewProvider = FutureProvider.autoDispose
    .family<BookingReview?, String>((ref, bookingId) {
      return ref.watch(reviewsRepositoryProvider).getForBooking(bookingId);
    });
