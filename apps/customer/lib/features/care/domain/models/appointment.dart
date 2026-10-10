class DoctorAppointment {
  final String id;
  final String doctorId;
  final String doctorName;
  final String specialty;
  final String hospital;
  final DateTime date;
  final String timeSlot;
  final String consultationType; // 'homeVisit' | 'teleconsult'
  final String status; // 'confirmed' | 'completed' | 'cancelled'
  final String patientName;
  final String? notes;

  /// The `bookings` row this appointment was paid through; null for
  /// records written before the link existed.
  final String? bookingId;

  const DoctorAppointment({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.specialty,
    required this.hospital,
    required this.date,
    required this.timeSlot,
    required this.consultationType,
    required this.status,
    required this.patientName,
    this.notes,
    this.bookingId,
  });

  DoctorAppointment withBooking(String? bookingId) => DoctorAppointment(
    id: id,
    doctorId: doctorId,
    doctorName: doctorName,
    specialty: specialty,
    hospital: hospital,
    date: date,
    timeSlot: timeSlot,
    consultationType: consultationType,
    status: status,
    patientName: patientName,
    notes: notes,
    bookingId: bookingId ?? this.bookingId,
  );
}
