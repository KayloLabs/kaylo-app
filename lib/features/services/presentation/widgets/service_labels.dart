import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../booking/domain/booking_draft.dart';
import '../../domain/service_info.dart';

String serviceUnitLabel(AppLocalizations l10n, ServiceUnit unit) =>
    switch (unit) {
      ServiceUnit.tree => l10n.unitTree,
      ServiceUnit.hour => l10n.unitHour,
      ServiceUnit.visit => l10n.unitVisit,
      ServiceUnit.order => l10n.unitOrder,
    };

String serviceUnitCount(AppLocalizations l10n, ServiceUnit unit, int count) =>
    switch (unit) {
      ServiceUnit.tree => l10n.unitTreeCount(count),
      ServiceUnit.hour => l10n.unitHourCount(count),
      ServiceUnit.visit => l10n.unitVisitCount(count),
      ServiceUnit.order => l10n.unitOrderCount(count),
    };

String serviceStandardLabel(AppLocalizations l10n, ServiceStandard standard) =>
    switch (standard) {
      ServiceStandard.safetyHarness => l10n.standardSafetyHarness,
      ServiceStandard.bunchProtection => l10n.standardBunchProtection,
      ServiceStandard.debrisCleared => l10n.standardDebrisCleared,
      ServiceStandard.groundNets => l10n.standardGroundNets,
      ServiceStandard.powerLineGuard => l10n.standardPowerLineGuard,
      ServiceStandard.woodChipping => l10n.standardWoodChipping,
      ServiceStandard.ecoCompost => l10n.standardEcoCompost,
      ServiceStandard.pestPrevention => l10n.standardPestPrevention,
      ServiceStandard.boundaryClearing => l10n.standardBoundaryClearing,
      ServiceStandard.verifiedWorker => l10n.standardVerifiedWorker,
      ServiceStandard.onTimeArrival => l10n.standardOnTimeArrival,
      ServiceStandard.fairPrice => l10n.standardFairPrice,
      ServiceStandard.partsQuoted => l10n.standardPartsQuoted,
      ServiceStandard.cleanupAfter => l10n.standardCleanupAfter,
      ServiceStandard.backgroundChecked => l10n.standardBackgroundChecked,
      ServiceStandard.prescriptionChecked => l10n.standardPrescriptionChecked,
    };

/// Section accent for a catalog category.
Color categoryAccent(String category) => switch (category) {
      'farm' => AppColors.farmAccent,
      'care' => AppColors.careAccent,
      _ => AppColors.homeAccent,
    };

String categoryTitle(AppLocalizations l10n, String category) =>
    switch (category) {
      'farm' => l10n.farmServices,
      'care' => l10n.careServices,
      'home' => l10n.homeServices,
      _ => l10n.allServices,
    };

String formatTimeSlot(BuildContext context, BookingTimeSlot slot) {
  final loc = MaterialLocalizations.of(context);
  TimeOfDay at(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  return '${loc.formatTimeOfDay(at(slot.startMinutes))} - '
      '${loc.formatTimeOfDay(at(slot.endMinutes))}';
}
