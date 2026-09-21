import '../../../core/models/service_item.dart';

/// How one unit of a service is counted and priced.
enum ServiceUnit { tree, hour, visit, order }

/// Commitments the worker makes for a service, shown as a checklist on
/// the details screen.
enum ServiceStandard {
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
  partsQuoted,
  cleanupAfter,
  backgroundChecked,
  prescriptionChecked,
}

class ServiceInfo {
  final ServiceUnit unit;
  final List<ServiceStandard> standards;

  const ServiceInfo(this.unit, this.standards);
}

/// The shared catalog carries name, price and description only; the
/// booking flow also needs to know what a unit is and what the worker
/// commits to. Matched on the service name so mock ids and live UUIDs
/// resolve alike.
ServiceInfo serviceInfoFor(ServiceItem service) {
  final name = service.name.toLowerCase();
  if (name.contains('coconut')) {
    return const ServiceInfo(ServiceUnit.tree, [
      ServiceStandard.safetyHarness,
      ServiceStandard.bunchProtection,
      ServiceStandard.debrisCleared,
    ]);
  }
  if (name.contains('arecanut')) {
    return const ServiceInfo(ServiceUnit.tree, [
      ServiceStandard.safetyHarness,
      ServiceStandard.groundNets,
      ServiceStandard.debrisCleared,
    ]);
  }
  if (name.contains('prun')) {
    return const ServiceInfo(ServiceUnit.tree, [
      ServiceStandard.powerLineGuard,
      ServiceStandard.woodChipping,
      ServiceStandard.safetyHarness,
    ]);
  }
  if (name.contains('clear')) {
    return const ServiceInfo(ServiceUnit.hour, [
      ServiceStandard.boundaryClearing,
      ServiceStandard.pestPrevention,
      ServiceStandard.debrisCleared,
    ]);
  }
  if (name.contains('garden')) {
    return const ServiceInfo(ServiceUnit.hour, [
      ServiceStandard.ecoCompost,
      ServiceStandard.pestPrevention,
      ServiceStandard.onTimeArrival,
    ]);
  }
  if (name.contains('clean')) {
    return const ServiceInfo(ServiceUnit.hour, [
      ServiceStandard.verifiedWorker,
      ServiceStandard.cleanupAfter,
      ServiceStandard.fairPrice,
    ]);
  }
  if (name.contains('plumb') || name.contains('electric')) {
    return const ServiceInfo(ServiceUnit.visit, [
      ServiceStandard.verifiedWorker,
      ServiceStandard.partsQuoted,
      ServiceStandard.cleanupAfter,
    ]);
  }
  if (name.contains('caregiver') || name.contains('care')) {
    return const ServiceInfo(ServiceUnit.visit, [
      ServiceStandard.backgroundChecked,
      ServiceStandard.verifiedWorker,
      ServiceStandard.onTimeArrival,
    ]);
  }
  if (name.contains('medicine')) {
    return const ServiceInfo(ServiceUnit.order, [
      ServiceStandard.prescriptionChecked,
      ServiceStandard.onTimeArrival,
      ServiceStandard.fairPrice,
    ]);
  }
  return const ServiceInfo(ServiceUnit.visit, [
    ServiceStandard.verifiedWorker,
    ServiceStandard.onTimeArrival,
    ServiceStandard.fairPrice,
  ]);
}
