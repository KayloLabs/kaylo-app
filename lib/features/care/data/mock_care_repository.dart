import '../domain/care_models.dart';
import '../domain/care_repository.dart';
import '../domain/models/appointment.dart';
import '../domain/models/caregiver.dart';
import '../domain/models/doctor.dart';

class MockCareRepository implements CareRepository {
  // --- M3 Data: Doctors & Caregivers ---
  final List<Doctor> _mockDoctors = [
    Doctor(
      id: 'doc1',
      name: 'Dr. Priya Nambiar',
      specialty: 'General Physician',
      hospital: 'Aster Medcity, Kochi',
      experienceYears: 14,
      rating: 4.9,
      reviewsCount: 142,
      consultationFee: 500,
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
      timeSlots: ['09:00 AM', '10:30 AM', '02:00 PM', '04:30 PM'],
      imageUrl: '',
      bio: 'Senior consultant in family medicine with over 14 years of experience specializing in geriatric and adult wellness care.',
    ),
    Doctor(
      id: 'doc2',
      name: 'Dr. Rajesh Varma',
      specialty: 'Cardiologist',
      hospital: 'Amrita Institute, Kochi',
      experienceYears: 18,
      rating: 4.9,
      reviewsCount: 210,
      consultationFee: 700,
      availableDays: ['Mon', 'Wed', 'Fri'],
      timeSlots: ['10:00 AM', '11:30 AM', '03:00 PM', '05:00 PM'],
      imageUrl: '',
      bio: 'Interventional cardiologist focused on preventative heart care, hypertension management, and senior cardiac health.',
    ),
    Doctor(
      id: 'doc3',
      name: 'Dr. Thomas George',
      specialty: 'Orthopedic',
      hospital: 'Lakeshore Hospital, Ernakulam',
      experienceYears: 12,
      rating: 4.8,
      reviewsCount: 98,
      consultationFee: 600,
      availableDays: ['Tue', 'Thu', 'Sat'],
      timeSlots: ['09:30 AM', '11:00 AM', '02:30 PM', '04:00 PM'],
      imageUrl: '',
      bio: 'Orthopedic specialist treating joint pain, arthritis, mobility challenges, and post-fall recovery.',
    ),
    Doctor(
      id: 'doc4',
      name: 'Dr. Meera Krishnan',
      specialty: 'Geriatrician',
      hospital: 'Silver Care Clinic, Kochi',
      experienceYears: 16,
      rating: 4.95,
      reviewsCount: 180,
      consultationFee: 550,
      availableDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
      timeSlots: ['09:00 AM', '11:00 AM', '03:00 PM'],
      imageUrl: '',
      bio: 'Dedicated geriatrician focused on holistic elder care, polypharmacy management, and cognitive wellness.',
    ),
    Doctor(
      id: 'doc5',
      name: 'Dr. Anand Padmanabhan',
      specialty: 'Ayurvedic',
      hospital: 'Kottakkal Arya Vaidya Sala, Ernakulam',
      experienceYears: 15,
      rating: 4.75,
      reviewsCount: 88,
      consultationFee: 400,
      availableDays: ['Mon', 'Tue', 'Thu', 'Fri', 'Sat'],
      timeSlots: ['10:00 AM', '02:00 PM', '04:00 PM'],
      imageUrl: '',
      bio: 'Ayurvedic physician offering authentic therapeutic management for chronic ailments, joint stiffness, and rejuvenation.',
    ),
  ];

  final List<Caregiver> _mockCaregivers = [
    Caregiver(
      id: 'cg1',
      name: 'Mary Varghese',
      rating: 4.9,
      reviewsCount: 64,
      hourlyRate: 250,
      experienceYears: 7,
      isVerified: true,
      imageUrl: '',
      specialties: ['Elderly Care', 'Mobility Assistance', 'Companionship'],
      bio: 'Certified senior caregiver with 7 years of hospital and in-home care experience. Patient, warm, and attentive.',
    ),
    Caregiver(
      id: 'cg2',
      name: 'Suma Prabhakaran',
      rating: 4.8,
      reviewsCount: 52,
      hourlyRate: 250,
      experienceYears: 5,
      isVerified: true,
      imageUrl: '',
      specialties: ['Elderly Care', 'Post-operative Care', 'Medication Support'],
      bio: 'Experienced in post-operative care, vital sign monitoring, and daily assistance for elderly individuals.',
    ),
    Caregiver(
      id: 'cg3',
      name: 'Jaya Chandran',
      rating: 4.7,
      reviewsCount: 38,
      hourlyRate: 220,
      experienceYears: 4,
      isVerified: true,
      imageUrl: '',
      specialties: ['Companionship', 'Mobility Assistance', 'Meal Prep'],
      bio: 'Compassionate companion caregiver fluent in Malayalam and English. Expert in gentle physical assistance.',
    ),
  ];

  final List<DoctorAppointment> _appointments = [
    DoctorAppointment(
      id: 'apt1',
      doctorId: 'doc1',
      doctorName: 'Dr. Priya Nambiar',
      specialty: 'General Physician',
      hospital: 'Aster Medcity, Kochi',
      date: DateTime.now().add(const Duration(days: 2)),
      timeSlot: '10:30 AM',
      consultationType: 'homeVisit',
      status: 'confirmed',
      patientName: 'Kunjamma V.',
      notes: 'Routine blood pressure and diabetic checkup.',
    ),
  ];

  final List<CaregiverBookingRecord> _caregiverBookings = [];

  // --- M5 Data: Reminders, Contacts & SOS ---
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

  // --- M3 Implementation ---
  @override
  Future<List<Doctor>> getDoctors({String? specialty}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (specialty == null || specialty.isEmpty) return _mockDoctors;
    return _mockDoctors
        .where((d) => d.specialty.toLowerCase() == specialty.toLowerCase())
        .toList();
  }

  @override
  Future<Doctor?> getDoctorById(String doctorId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockDoctors.where((d) => d.id == doctorId).firstOrNull;
  }

  @override
  Future<List<DoctorAppointment>> getDoctorAppointments() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_appointments);
  }

  @override
  Future<DoctorAppointment> bookDoctorAppointment(DoctorAppointment appointment) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _appointments.insert(0, appointment);
    return appointment;
  }

  @override
  Future<List<Caregiver>> getCaregivers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mockCaregivers);
  }

  @override
  Future<Caregiver?> getCaregiverById(String caregiverId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockCaregivers.where((c) => c.id == caregiverId).firstOrNull;
  }

  @override
  Future<List<CaregiverBookingRecord>> getCaregiverBookings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_caregiverBookings);
  }

  @override
  Future<CaregiverBookingRecord> bookCaregiver(CaregiverBookingRecord booking) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _caregiverBookings.insert(0, booking);
    return booking;
  }

  // --- M5 Implementation ---
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
