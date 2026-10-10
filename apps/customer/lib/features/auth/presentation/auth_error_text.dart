import 'package:flutter/widgets.dart';
import 'package:kaylo_core/auth/profile_store.dart';
import '../../../l10n/generated/app_localizations.dart';

String customerAuthErrorText(BuildContext context, Object error) {
  final l10n = AppLocalizations.of(context)!;
  return switch (error) {
    PartnerAccountNotAllowed() => l10n.partnerAccountNotAllowed,
    CustomerProfileUnavailable() => l10n.customerProfileUnavailable,
    _ => error.toString(),
  };
}
