/// An add-on a customer can tick on a service page, priced on top of the
/// visit. Ids are stable because they travel in URLs and in booking notes;
/// the label for an id comes from the translations (see
/// `sub_service_labels.dart`).
class SubService {
  final String id;
  final double price;
  const SubService(this.id, this.price);
}

/// The add-ons offered for a service, chosen by its name the same way the
/// labels always were. Prices are per add-on, on top of the visit.
List<SubService> subServicesFor(String serviceName) {
  final lower = serviceName.toLowerCase();
  if (lower.contains('plumb')) {
    return const [
      SubService('plumb_tap', 150),
      SubService('plumb_pipe', 200),
      SubService('plumb_drain', 250),
      SubService('plumb_install', 300),
    ];
  }
  if (lower.contains('electric')) {
    return const [
      SubService('elec_switch', 120),
      SubService('elec_wiring', 300),
      SubService('elec_fan', 200),
      SubService('elec_mcb', 250),
    ];
  }
  if (lower.contains('clean')) {
    return const [
      SubService('clean_deep', 600),
      SubService('clean_kitchen', 300),
      SubService('clean_bath', 250),
      SubService('clean_sofa', 350),
    ];
  }
  if (lower.contains('carpent')) {
    return const [
      SubService('carp_furniture', 300),
      SubService('carp_door', 250),
      SubService('carp_lock', 150),
      SubService('carp_custom', 500),
    ];
  }
  if (lower.contains('paint')) {
    return const [
      SubService('paint_interior', 1200),
      SubService('paint_exterior', 1500),
      SubService('paint_putty', 600),
      SubService('paint_waterproof', 900),
    ];
  }
  if (lower.contains('ac service') ||
      lower.contains('air condition') ||
      lower.contains('ac repair') ||
      lower == 'ac') {
    return const [
      SubService('ac_filter', 200),
      SubService('ac_gas', 800),
      SubService('ac_cooling', 300),
      SubService('ac_install', 600),
    ];
  }
  if (lower.contains('appliance')) {
    return const [
      SubService('appl_washer', 300),
      SubService('appl_fridge', 350),
      SubService('appl_microwave', 250),
      SubService('appl_tv', 300),
    ];
  }
  return const [
    SubService('gen_inspect', 100),
    SubService('gen_repair', 200),
    SubService('gen_install', 250),
    SubService('gen_maintain', 200),
  ];
}

/// The add-ons of [serviceName] whose ids are in [ids], in catalogue order.
/// Unknown ids are ignored, so a stale link cannot add an unpriced item.
List<SubService> subServicesByIds(String serviceName, Iterable<String> ids) {
  final wanted = ids.toSet();
  return subServicesFor(
    serviceName,
  ).where((s) => wanted.contains(s.id)).toList();
}

/// `extras=` query value: ids joined with commas.
String encodeSubServiceIds(Iterable<String> ids) => ids.join(',');

List<String> decodeSubServiceIds(String? value) =>
    value == null || value.isEmpty
    ? const []
    : value.split(',').where((id) => id.isNotEmpty).toList();
