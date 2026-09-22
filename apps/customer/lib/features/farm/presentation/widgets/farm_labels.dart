import 'package:flutter/material.dart';

import 'package:kaylo_ui/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/farm_booking_draft.dart';
import '../../domain/farm_service_info.dart';

/// Section accent for a catalog category.
Color categoryAccent(String category) => switch (category) {
  'farm' => AppColors.farmAccent,
  'care' => AppColors.careAccent,
  _ => AppColors.homeAccent,
};

String farmUnitLabel(AppLocalizations l10n, FarmUnit unit) => switch (unit) {
  FarmUnit.tree => l10n.unitTree,
  FarmUnit.hour => l10n.unitHour,
  FarmUnit.visit => l10n.unitVisit,
};

String farmUnitCount(AppLocalizations l10n, FarmUnit unit, int count) =>
    switch (unit) {
      FarmUnit.tree => l10n.unitTreeCount(count),
      FarmUnit.hour => l10n.unitHourCount(count),
      FarmUnit.visit => l10n.unitVisitCount(count),
    };

String farmStandardLabel(AppLocalizations l10n, FarmStandard standard) =>
    switch (standard) {
      FarmStandard.safetyHarness => l10n.standardSafetyHarness,
      FarmStandard.bunchProtection => l10n.standardBunchProtection,
      FarmStandard.debrisCleared => l10n.standardDebrisCleared,
      FarmStandard.groundNets => l10n.standardGroundNets,
      FarmStandard.powerLineGuard => l10n.standardPowerLineGuard,
      FarmStandard.woodChipping => l10n.standardWoodChipping,
      FarmStandard.ecoCompost => l10n.standardEcoCompost,
      FarmStandard.pestPrevention => l10n.standardPestPrevention,
      FarmStandard.boundaryClearing => l10n.standardBoundaryClearing,
      FarmStandard.verifiedWorker => l10n.standardVerifiedWorker,
      FarmStandard.onTimeArrival => l10n.standardOnTimeArrival,
      FarmStandard.fairPrice => l10n.standardFairPrice,
    };

String formatTimeSlot(BuildContext context, FarmTimeSlot slot) {
  final loc = MaterialLocalizations.of(context);
  TimeOfDay at(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  return '${loc.formatTimeOfDay(at(slot.startMinutes))} - '
      '${loc.formatTimeOfDay(at(slot.endMinutes))}';
}
