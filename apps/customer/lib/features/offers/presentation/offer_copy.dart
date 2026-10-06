import 'package:kaylo_core/utils/money.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../domain/kaylo_offer.dart';

/// Offer wording in the customer's language. The database sends English
/// for every offer; the codes this build knows are translated here, and an
/// offer added later falls back to what the database sent.
extension OfferCopy on KayloOffer {
  String titleIn(AppLocalizations l) => switch (code) {
    'FIRST100' => l.offerFirst100Title,
    'KAYLO150' => l.offerKaylo150Title,
    'WEEKEND100' => l.offerWeekend100Title,
    'WEEKDAY50' => l.offerWeekday50Title,
    'HOME80' => l.offerHome80Title,
    'FARM125' => l.offerFarm125Title,
    'CARE60' => l.offerCare60Title,
    'KAYLO300' => l.offerKaylo300Title,
    'NEXT75' => l.offerNext75Title,
    'THANKS120' => l.offerThanks120Title,
    _ => title,
  };

  String descriptionIn(AppLocalizations l) => switch (code) {
    'FIRST100' => l.offerFirst100Body,
    'KAYLO150' => l.offerKaylo150Body,
    'WEEKEND100' => l.offerWeekend100Body,
    'WEEKDAY50' => l.offerWeekday50Body,
    'HOME80' => l.offerHome80Body,
    'FARM125' => l.offerFarm125Body,
    'CARE60' => l.offerCare60Body,
    'KAYLO300' => l.offerKaylo300Body,
    'NEXT75' => l.offerNext75Body,
    'THANKS120' => l.offerThanks120Body,
    _ => description,
  };

  /// The kind of service this offer is for, or null when it is for any.
  String? categoryIn(AppLocalizations l) => switch (category) {
    'home' => l.labelHome,
    'farm' => l.labelFarm,
    'care' => l.care,
    _ => null,
  };

  /// Why the offer cannot be used, or null when it can. Without a
  /// [subtotal] the customer is only browsing, so only eligibility counts.
  String? reasonIn(AppLocalizations l, double? subtotal, {String? category}) {
    final block = subtotal == null
        ? (eligible ? null : OfferBlock.ineligible)
        : blockFor(subtotal, category: category);
    return switch (block) {
      null => null,
      OfferBlock.ineligible => switch (reasonCode) {
        'first_only' => l.offerReasonFirstOnly,
        'used' => l.offerReasonUsed,
        'reward_used' => l.offerReasonRewardUsed,
        'weekend_only' => l.offerReasonWeekend,
        'weekday_only' => l.offerReasonWeekday,
        'needs_confirmed' => l.offerReasonNeedsConfirmed,
        'needs_three' => l.offerReasonNeedsThree,
        _ => unavailableReason ?? l.offerNotAvailable,
      },
      OfferBlock.wrongCategory => switch (this.category) {
        'home' => l.offerReasonHomeOnly,
        'farm' => l.offerReasonFarmOnly,
        'care' => l.offerReasonCareOnly,
        _ => l.offerNotAvailable,
      },
      OfferBlock.belowMinimum => l.offerReasonAddMore(
        formatRupees((minimum - subtotal!).ceilToDouble()),
      ),
    };
  }
}
