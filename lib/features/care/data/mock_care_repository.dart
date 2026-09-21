import '../domain/care_models.dart';
import '../domain/care_repository.dart';

class MockCareRepository implements CareRepository {
  final List<MedicineReminder> _reminders = [
    const MedicineReminder(
      id: 'med-1',
      name: 'BP tablet (Telmisartan 40 mg)',
      dosage: '1 tablet after breakfast',
      hour: 8,
      minute: 0,
      isTakenToday: true,
    ),
    const MedicineReminder(
      id: 'med-2',
      name: 'Vitamin D3 and calcium',
      dosage: '1 capsule after lunch',
      hour: 13,
      minute: 0,
    ),
    const MedicineReminder(
      id: 'med-3',
      name: 'Cholesterol tablet',
      dosage: '1 tablet before bed',
      hour: 20,
      minute: 0,
      addedBy: 'Arjun (son)',
    ),
  ];

  final List<EmergencyContact> _contacts = [
    const EmergencyContact(
      id: 'c1',
      name: 'Arjun Nair',
      relation: 'Son',
      phone: '+91 98470 12345',
      isPrimary: true,
    ),
    const EmergencyContact(
      id: 'c2',
      name: 'Dr. Priya Mathew',
      relation: 'Family physician',
      phone: '+91 94471 88990',
    ),
    const EmergencyContact(
      id: 'c3',
      name: 'Sneha Nair',
      relation: 'Daughter',
      phone: '+91 98472 54321',
    ),
    const EmergencyContact(
      id: 'c4',
      name: 'Emergency helpline',
      relation: 'Ambulance and police',
      phone: '112',
    ),
  ];

  final List<SosAlert> _alerts = [
    SosAlert(
      id: 'sos-1',
      triggeredAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      status: SosStatus.resolved,
      notifiedContacts: 4,
      primaryContactName: 'Arjun Nair',
      location: 'Kannur, Kerala',
    ),
  ];

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<List<MedicineReminder>> getReminders(String userId) async {
    await Future.delayed(_latency);
    return List.unmodifiable(_reminders);
  }

  @override
  Future<MedicineReminder> addReminder(
    String userId, {
    required String name,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    await Future.delayed(_latency);
    final reminder = MedicineReminder(
      id: 'med-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      dosage: dosage,
      hour: hour,
      minute: minute,
    );
    _reminders.add(reminder);
    return reminder;
  }

  @override
  Future<void> setReminderTaken(String reminderId, bool taken) async {
    await Future.delayed(_latency);
    final index = _reminders.indexWhere((r) => r.id == reminderId);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(isTakenToday: taken);
    }
  }

  @override
  Future<List<EmergencyContact>> getContacts(String userId) async {
    await Future.delayed(_latency);
    return List.unmodifiable(_contacts);
  }

  @override
  Future<EmergencyContact> addContact(
    String userId, {
    required String name,
    required String relation,
    required String phone,
  }) async {
    await Future.delayed(_latency);
    final contact = EmergencyContact(
      id: 'c-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      relation: relation,
      phone: phone,
      isPrimary: _contacts.isEmpty,
    );
    _contacts.add(contact);
    return contact;
  }

  @override
  Future<void> setPrimaryContact(String userId, String contactId) async {
    await Future.delayed(_latency);
    for (var i = 0; i < _contacts.length; i++) {
      _contacts[i] = _contacts[i].copyWith(isPrimary: _contacts[i].id == contactId);
    }
  }

  @override
  Future<void> removeContact(String contactId) async {
    await Future.delayed(_latency);
    _contacts.removeWhere((c) => c.id == contactId);
    if (_contacts.isNotEmpty && !_contacts.any((c) => c.isPrimary)) {
      _contacts[0] = _contacts[0].copyWith(isPrimary: true);
    }
  }

  @override
  Future<List<SosAlert>> getSosHistory(String userId) async {
    await Future.delayed(_latency);
    return List.unmodifiable(_alerts);
  }

  @override
  Future<SosAlert> triggerSos(String userId, {String? location}) async {
    await Future.delayed(_latency);
    final primary = _contacts.where((c) => c.isPrimary).firstOrNull ??
        _contacts.firstOrNull;
    final alert = SosAlert(
      id: 'sos-${DateTime.now().millisecondsSinceEpoch}',
      triggeredAt: DateTime.now(),
      status: SosStatus.open,
      notifiedContacts: _contacts.length,
      primaryContactName: primary?.name,
      location: location,
    );
    _alerts.insert(0, alert);
    return alert;
  }
}
