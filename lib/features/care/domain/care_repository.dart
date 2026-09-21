import 'models/appointment.dart';
import 'models/caregiver.dart';
import 'models/doctor.dart';

abstract class CareRepository {
  Future<List<Doctor>> getDoctors({String? specialty});
  Future<Doctor?> getDoctorById(String doctorId);
  Future<List<DoctorAppointment>> getDoctorAppointments();
  Future<DoctorAppointment> bookDoctorAppointment(DoctorAppointment appointment);

  Future<List<Caregiver>> getCaregivers();
  Future<Caregiver?> getCaregiverById(String caregiverId);
  Future<List<CaregiverBookingRecord>> getCaregiverBookings();
  Future<CaregiverBookingRecord> bookCaregiver(CaregiverBookingRecord booking);
}
