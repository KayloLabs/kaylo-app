import 'package:kaylo_core/models/service_item.dart';

/// A window of the day a worker can be booked for, in minutes from
/// midnight so the domain stays free of Flutter types.
class FarmTimeSlot {
  final int startMinutes;
  final int endMinutes;

  const FarmTimeSlot(this.startMinutes, this.endMinutes);

  static const List<FarmTimeSlot> all = [
    FarmTimeSlot(7 * 60, 9 * 60),
    FarmTimeSlot(8 * 60, 10 * 60),
    FarmTimeSlot(10 * 60 + 30, 12 * 60 + 30),
    FarmTimeSlot(14 * 60, 16 * 60),
    FarmTimeSlot(16 * 60 + 30, 18 * 60 + 30),
  ];

  /// The slot whose start is nearest to [dateTime]'s time of day, so a
  /// reschedule sheet opens on the booking's current slot.
  static FarmTimeSlot closestTo(DateTime dateTime) {
    final minutes = dateTime.hour * 60 + dateTime.minute;
    var best = all.first;
    for (final slot in all) {
      if ((slot.startMinutes - minutes).abs() <
          (best.startMinutes - minutes).abs()) {
        best = slot;
      }
    }
    return best;
  }
}

/// Everything the customer has chosen on the way to payment. Immutable;
/// the schedule screen builds it up with [copyWith].
class FarmBookingDraft {
  final ServiceItem service;
  final DateTime date;
  final FarmTimeSlot slot;
  final int quantity;
  final String address;

  /// Set when the customer picked a specific worker on the way in
  /// (worker list or profile); null lets Kaylo assign one.
  final String? workerId;

  const FarmBookingDraft({
    required this.service,
    required this.date,
    required this.slot,
    required this.quantity,
    required this.address,
    this.workerId,
  });

  double get total => service.basePrice * quantity;

  DateTime get scheduledAt => DateTime(
    date.year,
    date.month,
    date.day,
    slot.startMinutes ~/ 60,
    slot.startMinutes % 60,
  );

  FarmBookingDraft copyWith({
    DateTime? date,
    FarmTimeSlot? slot,
    int? quantity,
    String? address,
  }) {
    return FarmBookingDraft(
      service: service,
      date: date ?? this.date,
      slot: slot ?? this.slot,
      quantity: quantity ?? this.quantity,
      address: address ?? this.address,
      workerId: workerId,
    );
  }
}
