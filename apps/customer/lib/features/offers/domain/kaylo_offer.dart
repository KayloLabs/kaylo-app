import 'package:kaylo_core/models/booking.dart';

/// Offers are fixed-value discounts, never a random cash prize. Amounts are INR.
class KayloOffer {
  final String code;
  final String title;
  final String description;
  final double discount;
  final double minimum;
  final bool eligible;
  final String? unavailableReason;
  final bool scratch;

  const KayloOffer({
    required this.code,
    required this.title,
    required this.description,
    required this.discount,
    required this.minimum,
    this.eligible = true,
    this.unavailableReason,
    this.scratch = false,
  });

  factory KayloOffer.fromJson(Map<String, dynamic> json) => KayloOffer(
    code: json['code'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    discount: (json['discount'] as num).toDouble(),
    minimum: (json['minimum'] as num).toDouble(),
    eligible: json['eligible'] == true,
    unavailableReason: json['reason'] as String?,
    scratch: json['scratch'] == true,
  );

  bool appliesTo(double subtotal) =>
      eligible && subtotal >= minimum && subtotal > discount;
  double savings(double subtotal) => appliesTo(subtotal) ? discount : 0;
  String? reasonFor(double subtotal) => !eligible
      ? unavailableReason
      : subtotal < minimum
      ? 'Add ₹${(minimum - subtotal).ceil()} more to use this offer'
      : null;
}

List<KayloOffer> demoOffers(List<Booking> bookings, DateTime now) {
  final active = bookings
      .where((b) => b.status != BookingStatus.cancelled)
      .toList();
  final finished = active.any(
    (b) =>
        b.status == BookingStatus.confirmed ||
        b.status == BookingStatus.inProgress ||
        b.status == BookingStatus.completed,
  );
  bool used(String code) => active.any((b) => b.offerCode == code);
  final weekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;
  return [
    KayloOffer(
      code: 'FIRST100',
      title: 'Your first one is special',
      description: '₹100 off your first booking of ₹499 or more.',
      discount: 100,
      minimum: 499,
      eligible: active.isEmpty,
      unavailableReason: active.isEmpty ? null : 'For your first booking only',
    ),
    KayloOffer(
      code: 'KAYLO150',
      title: 'A little help with bigger jobs',
      description: '₹150 off a booking of ₹1,499 or more. Once per account.',
      discount: 150,
      minimum: 1499,
      eligible: !used('KAYLO150'),
      unavailableReason: used('KAYLO150') ? 'Already used' : null,
    ),
    KayloOffer(
      code: 'WEEKEND100',
      title: 'A weekend well spent',
      description:
          '₹100 off ₹999 or more on Saturdays and Sundays. Once per account.',
      discount: 100,
      minimum: 999,
      eligible: weekend && !used('WEEKEND100'),
      unavailableReason: used('WEEKEND100')
          ? 'Already used'
          : !weekend
          ? 'Available on weekends'
          : null,
    ),
    KayloOffer(
      code: 'NEXT75',
      title: 'Something for next time',
      description:
          '₹75 off your next booking of ₹799 or more. Unlocks after a confirmed booking.',
      discount: 75,
      minimum: 799,
      scratch: true,
      eligible: finished && !used('NEXT75'),
      unavailableReason: used('NEXT75')
          ? 'Reward used'
          : !finished
          ? 'Unlocks after your first confirmed booking'
          : null,
    ),
  ];
}
