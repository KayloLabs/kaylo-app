import '../../../core/models/service_item.dart';
import '../../../core/models/worker.dart';

/// Carries user selections from [BookServiceScreen] to [BookingPaymentScreen].
class BookingDraft {
  final ServiceItem service;
  final Worker? worker;
  final DateTime date;
  final String timeSlot;
  final String address;
  final String notes;
  final double total;

  const BookingDraft({
    required this.service,
    this.worker,
    required this.date,
    required this.timeSlot,
    required this.address,
    this.notes = '',
    required this.total,
  });

  /// The combined DateTime represented by the selected date and time slot.
  DateTime get scheduledAt {
    // Slots are displayed as ranges (for example, "01:00 PM - 04:00 PM").
    // Persist their start time rather than attempting to infer an hour from
    // arbitrary digits elsewhere in the range.
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)',
      caseSensitive: false,
    ).firstMatch(timeSlot.trim());
    if (match == null) {
      return DateTime(date.year, date.month, date.day, 9);
    }

    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final isPm = match.group(3)!.toUpperCase() == 'PM';
    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
