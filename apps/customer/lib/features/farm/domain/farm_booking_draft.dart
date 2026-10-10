import 'package:kaylo_core/models/service_item.dart';

import '../../home/domain/sub_service.dart';

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

  /// True when any held booking time (minutes from midnight) falls inside
  /// this slot's window.
  bool isTakenBy(Set<int> heldMinutes) =>
      heldMinutes.any((m) => m >= startMinutes && m < endMinutes);

  /// The first slot of the day nobody holds, or null when the day is full.
  static FarmTimeSlot? firstFree(Set<int> heldMinutes) {
    for (final slot in all) {
      if (!slot.isTakenBy(heldMinutes)) return slot;
    }
    return null;
  }

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
  final String? locationId;
  final double? latitude;
  final double? longitude;

  /// Set when the customer picked a specific worker on the way in
  /// (worker list or profile); null lets Kaylo assign one.
  final String? workerId;

  /// Add-ons ticked on the service page, each priced on top of the visit.
  final List<SubService> addOns;

  /// The add-ons as one translated line for the worker's instructions,
  /// set by the schedule screen (the domain has no translations).
  final String? addOnsNote;

  const FarmBookingDraft({
    required this.service,
    required this.date,
    required this.slot,
    required this.quantity,
    required this.address,
    this.workerId,
    this.locationId,
    this.latitude,
    this.longitude,
    this.addOns = const [],
    this.addOnsNote,
  });

  /// Keep the exact pin in the worker's existing instructions field, including
  /// one-off locations that the customer did not choose to save permanently.
  String get bookingNotes {
    final lines = [
      if (addOnsNote != null && addOnsNote!.isNotEmpty) addOnsNote!,
      address,
      if (latitude != null && longitude != null)
        'Map: https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
    ];
    return lines.join('\n');
  }

  double get addOnsTotal => addOns.fold<double>(0, (sum, a) => sum + a.price);

  double get total => service.basePrice * quantity + addOnsTotal;

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
    String? locationId,
    double? latitude,
    double? longitude,
    bool clearLocation = false,
    List<SubService>? addOns,
    String? addOnsNote,
  }) {
    return FarmBookingDraft(
      service: service,
      date: date ?? this.date,
      slot: slot ?? this.slot,
      quantity: quantity ?? this.quantity,
      address: address ?? this.address,
      workerId: workerId,
      locationId: clearLocation ? null : locationId ?? this.locationId,
      latitude: clearLocation ? null : latitude ?? this.latitude,
      longitude: clearLocation ? null : longitude ?? this.longitude,
      addOns: addOns ?? this.addOns,
      addOnsNote: addOnsNote ?? this.addOnsNote,
    );
  }
}
