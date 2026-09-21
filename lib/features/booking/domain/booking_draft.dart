import '../../../core/models/service_item.dart';

/// A window of the day a worker can be booked for, in minutes from
/// midnight so the domain stays free of Flutter types.
class BookingTimeSlot {
  final int startMinutes;
  final int endMinutes;

  const BookingTimeSlot(this.startMinutes, this.endMinutes);

  static const List<BookingTimeSlot> all = [
    BookingTimeSlot(7 * 60, 9 * 60),
    BookingTimeSlot(8 * 60, 10 * 60),
    BookingTimeSlot(10 * 60 + 30, 12 * 60 + 30),
    BookingTimeSlot(14 * 60, 16 * 60),
    BookingTimeSlot(16 * 60 + 30, 18 * 60 + 30),
  ];

  /// The slot a booking's time falls in, or the closest one, so a
  /// reschedule sheet can preselect it.
  static BookingTimeSlot closestTo(DateTime dateTime) {
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
class BookingDraft {
  final ServiceItem service;
  final DateTime date;
  final BookingTimeSlot slot;
  final int quantity;
  final String address;

  const BookingDraft({
    required this.service,
    required this.date,
    required this.slot,
    required this.quantity,
    required this.address,
  });

  double get total => service.basePrice * quantity;

  DateTime get scheduledAt => DateTime(
        date.year,
        date.month,
        date.day,
        slot.startMinutes ~/ 60,
        slot.startMinutes % 60,
      );

  BookingDraft copyWith({
    DateTime? date,
    BookingTimeSlot? slot,
    int? quantity,
    String? address,
  }) {
    return BookingDraft(
      service: service,
      date: date ?? this.date,
      slot: slot ?? this.slot,
      quantity: quantity ?? this.quantity,
      address: address ?? this.address,
    );
  }
}
