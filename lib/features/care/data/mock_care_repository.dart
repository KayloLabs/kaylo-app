import '../domain/care_repository.dart';
import '../domain/models/appointment.dart';
import '../domain/models/caregiver.dart';
import '../domain/models/doctor.dart';

class MockCareRepository implements CareRepository {
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
}
