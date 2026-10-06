import 'package:kaylo_core/models/booking.dart';

/// Why an offer cannot be used on a particular booking right now.
enum OfferBlock { ineligible, wrongCategory, belowMinimum }

/// Offers are fixed-value discounts, never a random cash prize. Amounts are INR.
class KayloOffer {
  final String code;
  final String title;
  final String description;
  final double discount;
  final double minimum;
  final bool eligible;
  final String? unavailableReason;

  /// The server's machine-readable reason ('used', 'weekend_only', ...), so
  /// the screen can explain in the customer's language.
  final String? reasonCode;

  /// 'home', 'farm' or 'care' when the offer is for one kind of service.
  final String? category;
  final bool scratch;

  const KayloOffer({
    required this.code,
    required this.title,
    required this.description,
    required this.discount,
    required this.minimum,
    this.eligible = true,
    this.unavailableReason,
    this.reasonCode,
    this.category,
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
    reasonCode: json['reason_code'] as String?,
    category: json['category'] as String?,
    scratch: json['scratch'] == true,
  );

  /// [category] is the booking's kind of service. Leave it out while only
  /// browsing: an offer for one kind of service is then not ruled out.
  OfferBlock? blockFor(double subtotal, {String? category}) {
    if (!eligible) return OfferBlock.ineligible;
    if (this.category != null &&
        category != null &&
        this.category != category) {
      return OfferBlock.wrongCategory;
    }
    if (subtotal < minimum || subtotal <= discount) {
      return OfferBlock.belowMinimum;
    }
    return null;
  }

  bool appliesTo(double subtotal, {String? category}) =>
      blockFor(subtotal, category: category) == null;
  double savings(double subtotal, {String? category}) =>
      appliesTo(subtotal, category: category) ? discount : 0;

  /// English wording for logs and the sample build; screens localise instead.
  String? reasonFor(double subtotal, {String? category}) =>
      switch (blockFor(subtotal, category: category)) {
        OfferBlock.ineligible => unavailableReason,
        OfferBlock.wrongCategory =>
          'This offer is for ${this.category} bookings only',
        OfferBlock.belowMinimum =>
          'Add ₹${(minimum - subtotal).ceil()} more to use this offer',
        null => null,
      };
}

/// The sample build's offers. The rules mirror `kaylo_available_offers` in
/// the database, which is what the live app asks.
List<KayloOffer> demoOffers(List<Booking> bookings, DateTime now) {
  final active = bookings
      .where((b) => b.status != BookingStatus.cancelled)
      .toList();
  final settled = active
      .where(
        (b) =>
            b.status == BookingStatus.confirmed ||
            b.status == BookingStatus.inProgress ||
            b.status == BookingStatus.completed,
      )
      .length;
  bool used(String code) => active.any((b) => b.offerCode == code);
  final weekend =
      now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

  KayloOffer offer(
    String code,
    String title,
    String description,
    double discount,
    double minimum, {
    String? category,
    bool scratch = false,
    String? why,
  }) => KayloOffer(
    code: code,
    title: title,
    description: description,
    discount: discount,
    minimum: minimum,
    category: category,
    scratch: scratch,
    eligible: why == null,
    reasonCode: why,
    unavailableReason: switch (why) {
      'first_only' => 'For your first booking only',
      'used' => 'Already used',
      'reward_used' => 'Reward used',
      'weekend_only' => 'Available on weekends',
      'weekday_only' => 'Available Monday to Friday',
      'needs_confirmed' => 'Unlocks after your first confirmed booking',
      'needs_three' => 'Unlocks after three confirmed bookings',
      _ => null,
    },
  );
  String? once(String code) => used(code) ? 'used' : null;

  return [
    offer(
      'FIRST100',
      'Your first one is special',
      '₹100 off your first booking of ₹499 or more.',
      100,
      499,
      why: active.isEmpty ? null : 'first_only',
    ),
    offer(
      'KAYLO150',
      'A little help with bigger jobs',
      '₹150 off a booking of ₹1,499 or more. Once per account.',
      150,
      1499,
      why: once('KAYLO150'),
    ),
    offer(
      'WEEKEND100',
      'A weekend well spent',
      '₹100 off ₹999 or more on Saturdays and Sundays. Once per account.',
      100,
      999,
      why: once('WEEKEND100') ?? (weekend ? null : 'weekend_only'),
    ),
    offer(
      'WEEKDAY50',
      'A midweek lift',
      '₹50 off ₹599 or more, Monday to Friday. Once per account.',
      50,
      599,
      why: once('WEEKDAY50') ?? (weekend ? 'weekday_only' : null),
    ),
    offer(
      'HOME80',
      'Home, sorted',
      '₹80 off a home service of ₹499 or more. Once per account.',
      80,
      499,
      category: 'home',
      why: once('HOME80'),
    ),
    offer(
      'FARM125',
      'For the land that feeds us',
      '₹125 off a farm service of ₹999 or more. Once per account.',
      125,
      999,
      category: 'farm',
      why: once('FARM125'),
    ),
    offer(
      'CARE60',
      'Care, made a little lighter',
      '₹60 off a Care booking of ₹399 or more. Once per account.',
      60,
      399,
      category: 'care',
      why: once('CARE60'),
    ),
    offer(
      'KAYLO300',
      'For the really big days',
      '₹300 off a booking of ₹2,999 or more. Once per account.',
      300,
      2999,
      why: once('KAYLO300'),
    ),
    offer(
      'NEXT75',
      'Something for next time',
      '₹75 off your next booking of ₹799 or more. Unlocks after a confirmed booking.',
      75,
      799,
      scratch: true,
      why: used('NEXT75')
          ? 'reward_used'
          : settled < 1
          ? 'needs_confirmed'
          : null,
    ),
    offer(
      'THANKS120',
      'Three bookings in. Thank you.',
      '₹120 off a booking of ₹999 or more. Unlocks after three confirmed bookings.',
      120,
      999,
      scratch: true,
      why: used('THANKS120')
          ? 'reward_used'
          : settled < 3
          ? 'needs_three'
          : null,
    ),
  ];
}
