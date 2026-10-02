import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/services/sound_service.dart';
import '../../notifications/application/booking_reminders.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:uuid/uuid.dart';
import '../../auth/application/current_user_provider.dart';
import '../../booking/application/bookings_providers.dart';
import '../../home/application/home_providers.dart';
import 'care_providers.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Kept for the lifetime of a checkout screen, so retries reuse its pending booking.
class CareCheckout {
  String? _requestId;
  String? _fingerprint;
  Future<bool> pay(
    WidgetRef ref, {
    required String kind,
    required Map<String, dynamic> details,
    required double mockAmount,
  }) async {
    final l10n = AppLocalizations.of(ref.context)!;
    final fingerprint = '$kind:$details';
    if (_fingerprint != fingerprint) {
      _requestId = const Uuid().v4();
      _fingerprint = fingerprint;
    }
    final String bookingId;
    if (useMockData) {
      final services = await ref
          .read(homeRepositoryProvider)
          .getServicesByCategory('care');
      final service = services
          .where((s) => s.name.toLowerCase().contains(kind))
          .firstOrNull;
      if (service == null) {
        throw StateError(l10n.careServiceUnavailable);
      }
      final booking = await ref
          .read(bookingsRepositoryProvider)
          .createBooking(
            Booking(
              id: _requestId!,
              userId: ref.read(currentUserIdProvider)!,
              serviceId: service.id,
              scheduledAt: DateTime.parse(details['date'] as String),
              status: BookingStatus.pending,
              totalAmount: mockAmount,
            ),
          );
      bookingId = booking.id;
    } else {
      bookingId =
          await ref
                  .read(supabaseClientProvider)
                  .rpc(
                    'create_care_checkout',
                    params: {
                      'p_request_id': _requestId,
                      'p_kind': kind,
                      'p_details': details,
                    },
                  )
              as String;
      final row = await ref
          .read(supabaseClientProvider)
          .from('bookings')
          .select('status')
          .eq('booking_id', bookingId)
          .single();
      if (row['status'] == 'confirmed') {
        _refresh(ref);
        return true;
      }
    }
    final outcome = await ref
        .read(paymentGatewayProvider)
        .pay(bookingId: bookingId, email: ref.read(currentUserProvider)?.email);
    if (!outcome.paid) {
      throw StateError(outcome.message ?? l10n.appointmentNotConfirmed);
    }
    if (useMockData) {
      await ref
          .read(bookingsRepositoryProvider)
          .updateBookingStatus(bookingId, BookingStatus.confirmed);
    }
    // Payment already succeeded. A notification or refresh failure must not
    // present the checkout as unpaid or encourage a second payment.
    try {
      final bookings = await ref
          .read(bookingsRepositoryProvider)
          .getUserBookings(ref.read(currentUserIdProvider)!);
      final confirmed = bookings.where((b) => b.id == bookingId).firstOrNull;
      if (confirmed != null) {
        await ref
            .read(bookingRemindersProvider)
            .received(
              confirmed,
              kind == 'doctor' ? l10n.doctorAppointment : l10n.caregiverBooking,
            );
      }
      KayloFeedback.success();
      ref.read(soundServiceProvider).playSuccess();
    } catch (_) {}
    _refresh(ref);
    return true;
  }

  void _refresh(WidgetRef ref) {
    if (!ref.context.mounted) return;
    ref.invalidate(userBookingsProvider);
    ref.invalidate(doctorAppointmentsProvider);
    ref.invalidate(caregiverBookingsProvider);
  }
}
