import 'care_models.dart';

abstract class CareRepository {
  Future<List<MedicineReminder>> getReminders(String userId);
  Future<MedicineReminder> addReminder(
    String userId, {
    required String name,
    required String dosage,
    required int hour,
    required int minute,
  });
  Future<void> setReminderTaken(String reminderId, bool taken);

  Future<List<EmergencyContact>> getContacts(String userId);
  Future<EmergencyContact> addContact(
    String userId, {
    required String name,
    required String relation,
    required String phone,
  });
  Future<void> setPrimaryContact(String userId, String contactId);
  Future<void> removeContact(String contactId);

  Future<List<SosAlert>> getSosHistory(String userId);
  Future<SosAlert> triggerSos(String userId, {String? location});
}
