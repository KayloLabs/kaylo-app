import '../../../core/models/service_item.dart';

/// How one unit of a farm service is counted and priced.
enum FarmUnit { tree, hour, visit }

/// Commitments the worker makes for a service, shown as a checklist on
/// the details screen.
enum FarmStandard {
  safetyHarness,
  bunchProtection,
  debrisCleared,
  groundNets,
  powerLineGuard,
  woodChipping,
  ecoCompost,
  pestPrevention,
  boundaryClearing,
  verifiedWorker,
  onTimeArrival,
  fairPrice,
}

class FarmServiceInfo {
  final FarmUnit unit;
  final List<FarmStandard> standards;

  const FarmServiceInfo(this.unit, this.standards);
}

/// The shared catalog carries name, price and description only; the farm
/// flow also needs to know what a unit is and what the worker commits to.
/// Matched on the service name so mock ids and live UUIDs resolve alike.
FarmServiceInfo farmInfoFor(ServiceItem service) {
  final name = service.name.toLowerCase();
  if (name.contains('coconut')) {
    return const FarmServiceInfo(FarmUnit.tree, [
      FarmStandard.safetyHarness,
      FarmStandard.bunchProtection,
      FarmStandard.debrisCleared,
    ]);
  }
  if (name.contains('arecanut')) {
    return const FarmServiceInfo(FarmUnit.tree, [
      FarmStandard.safetyHarness,
      FarmStandard.groundNets,
      FarmStandard.debrisCleared,
    ]);
  }
  if (name.contains('prun')) {
    return const FarmServiceInfo(FarmUnit.tree, [
      FarmStandard.powerLineGuard,
      FarmStandard.woodChipping,
      FarmStandard.safetyHarness,
    ]);
  }
  if (name.contains('clear')) {
    return const FarmServiceInfo(FarmUnit.hour, [
      FarmStandard.boundaryClearing,
      FarmStandard.pestPrevention,
      FarmStandard.debrisCleared,
    ]);
  }
  if (name.contains('garden')) {
    return const FarmServiceInfo(FarmUnit.hour, [
      FarmStandard.ecoCompost,
      FarmStandard.pestPrevention,
      FarmStandard.onTimeArrival,
    ]);
  }
  return const FarmServiceInfo(FarmUnit.visit, [
    FarmStandard.verifiedWorker,
    FarmStandard.onTimeArrival,
    FarmStandard.fairPrice,
  ]);
}
