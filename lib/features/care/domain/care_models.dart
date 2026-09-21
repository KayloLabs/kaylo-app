class MedicineReminder {
  final String id;
  final String name;
  final String dosage;
  final int hour;
  final int minute;
  final bool isTakenToday;

  /// Who set the reminder when it was not the senior themselves (a
  /// family member or doctor acting remotely).
  final String? addedBy;

  const MedicineReminder({
    required this.id,
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
    this.isTakenToday = false,
    this.addedBy,
  });

  int get minutesOfDay => hour * 60 + minute;

  MedicineReminder copyWith({bool? isTakenToday}) {
    return MedicineReminder(
      id: id,
      name: name,
      dosage: dosage,
      hour: hour,
      minute: minute,
      isTakenToday: isTakenToday ?? this.isTakenToday,
      addedBy: addedBy,
    );
  }
}

class EmergencyContact {
  final String id;
  final String name;
  final String relation;
  final String phone;
  final bool isPrimary;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    this.isPrimary = false,
  });

  EmergencyContact copyWith({bool? isPrimary}) {
    return EmergencyContact(
      id: id,
      name: name,
      relation: relation,
      phone: phone,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}

/// Mirrors the `sos_status` enum.
enum SosStatus { open, acknowledged, resolved }

class SosAlert {
  final String id;
  final DateTime triggeredAt;
  final SosStatus status;
  final int notifiedContacts;
  final String? primaryContactName;
  final String? location;

  const SosAlert({
    required this.id,
    required this.triggeredAt,
    required this.status,
    required this.notifiedContacts,
    this.primaryContactName,
    this.location,
  });
}
