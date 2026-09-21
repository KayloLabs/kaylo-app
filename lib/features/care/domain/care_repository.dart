import 'care_models.dart';
import 'models/appointment.dart';
import 'models/caregiver.dart';
import 'models/doctor.dart';

abstract class CareRepository {
  // M3: Doctor & Caregiver
  Future<List<Doctor>> getDoctors({String? specialty});
  Future<Doctor?> getDoctorById(String doctorId);
  Future<List<DoctorAppointment>> getDoctorAppointments();
  Future<DoctorAppointment> bookDoctorAppointment(DoctorAppointment appointment);

  Future<List<Caregiver>> getCaregivers();
  Future<Caregiver?> getCaregiverById(String caregiverId);
  Future<List<CaregiverBookingRecord>> getCaregiverBookings();
  Future<CaregiverBookingRecord> bookCaregiver(CaregiverBookingRecord booking);

  // M5: Reminders, Contacts & SOS
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
