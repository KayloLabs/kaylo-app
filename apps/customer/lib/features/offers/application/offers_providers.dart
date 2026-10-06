import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../auth/application/current_user_provider.dart';
import '../../booking/application/bookings_providers.dart';
import '../../booking/data/mock_bookings_repository.dart';
import '../../home/application/home_providers.dart';
import '../domain/kaylo_offer.dart';

final bookingOfferApplierProvider = Provider(
  (ref) =>
      (Booking booking, String? code) => applyBookingOffer(ref, booking, code),
);

final offersProvider = FutureProvider.autoDispose<List<KayloOffer>>((
  ref,
) async {
  final user = ref.watch(currentUserIdProvider);
  if (user == null) return [];
  if (useMockData) {
    return demoOffers(
      await ref.watch(userBookingsProvider.future),
      DateTime.now(),
    );
  }
  // Re-evaluate eligibility after a booking, cancellation or account change.
  ref.watch(userBookingsProvider);
  final rows = await ref
      .watch(supabaseClientProvider)
      .rpc('kaylo_available_offers');
  return (rows as List)
      .map((row) => KayloOffer.fromJson(Map<String, dynamic>.from(row as Map)))
      .toList();
});

/// Apply before opening Razorpay: its order reads this discounted booking total.
/// The database rechecks eligibility; a visual reveal does not redeem a coupon.
Future<Booking> applyBookingOffer(
  Ref ref,
  Booking booking,
  String? code,
) async {
  if (code == null) return booking;
  if (useMockData) {
    if (booking.offerCode == code && booking.discountAmount > 0) return booking;
    final history = await ref
        .read(bookingsRepositoryProvider)
        .getUserBookings(ref.read(currentUserIdProvider)!);
    final offer = demoOffers(
      history.where((b) => b.id != booking.id).toList(),
      DateTime.now(),
    ).where((o) => o.code == code).firstOrNull;
    // The database reads the booking's service; the sample build asks the
    // sample catalogue the same question.
    final category =
        (await ref
                .read(homeRepositoryProvider)
                .getServiceById(booking.serviceId))
            ?.category;
    if (offer == null ||
        !offer.appliesTo(booking.totalAmount, category: category)) {
      throw ServerFailure(
        offer?.reasonFor(booking.totalAmount, category: category) ??
            'This offer is not available',
      );
    }
    final discounted = booking.copyWith(
      totalAmount: booking.totalAmount - offer.discount,
      subtotalAmount: booking.totalAmount,
      discountAmount: offer.discount,
      offerCode: code,
    );
    final repo = ref.read(bookingsRepositoryProvider);
    if (repo is MockBookingsRepository) repo.applyOffer(discounted);
    return discounted;
  }
  try {
    final data = await ref
        .read(supabaseClientProvider)
        .rpc(
          'kaylo_apply_booking_offer',
          params: {'p_booking_id': booking.id, 'p_code': code},
        );
    final row = Map<String, dynamic>.from(data as Map);
    return booking.copyWith(
      totalAmount: (row['estimated_cost'] as num).toDouble(),
      subtotalAmount: (row['subtotal_amount'] as num).toDouble(),
      discountAmount: (row['discount_amount'] as num).toDouble(),
      offerCode: row['offer_code'] as String?,
    );
  } catch (error) {
    throw mapSupabaseError(error);
  }
}
