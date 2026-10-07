import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/booking_review.dart';
import '../domain/reviews_repository.dart';

/// Reviews kept on the device, so the sample build remembers them across
/// restarts the way the live one does.
class MockReviewsRepository implements ReviewsRepository {
  final SharedPreferences? _prefs;
  static const _storageKey = 'kaylo_booking_reviews';
  Map<String, BookingReview>? _cache;

  MockReviewsRepository([this._prefs]);

  Map<String, BookingReview> _load() {
    if (_cache != null) return _cache!;
    final raw = _prefs?.getString(_storageKey);
    final map = <String, BookingReview>{};
    if (raw != null && raw.isNotEmpty) {
      for (final item in jsonDecode(raw) as List<dynamic>) {
        final review = BookingReview.fromJson(item as Map<String, dynamic>);
        map[review.bookingId] = review;
      }
    }
    return _cache = map;
  }

  Future<void> _persist() async {
    final list = _load().values.map((r) => r.toJson()).toList();
    await _prefs?.setString(_storageKey, jsonEncode(list));
  }

  @override
  Future<BookingReview?> getForBooking(String bookingId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _load()[bookingId];
  }

  @override
  Future<BookingReview> submit({
    required String bookingId,
    required String workerId,
    required int rating,
    String? text,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (rating < 1 || rating > 5) {
      throw ArgumentError.value(rating, 'rating', 'must be 1 to 5');
    }
    final trimmed = text?.trim();
    final review = BookingReview(
      bookingId: bookingId,
      workerId: workerId,
      rating: rating,
      text: trimmed == null || trimmed.isEmpty ? null : trimmed,
      createdAt: _load()[bookingId]?.createdAt ?? DateTime.now(),
    );
    _load()[bookingId] = review;
    await _persist();
    return review;
  }
}
