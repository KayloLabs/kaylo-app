import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/care_repository.dart';
import '../domain/models/appointment.dart';
import '../domain/models/caregiver.dart';
import '../domain/models/doctor.dart';
import 'mock_care_repository.dart';

class SupabaseCareRepository implements CareRepository {
  final SupabaseClient _client;
  final MockCareRepository _fallback = MockCareRepository();

  SupabaseCareRepository(this._client);

  @override
  Future<List<Doctor>> getDoctors({String? specialty}) async {
    try {
      final query = _client.from('doctors').select();
      final rows = specialty != null && specialty.isNotEmpty
          ? await query.eq('specialty', specialty)
          : await query;
      if (rows.isEmpty) return await _fallback.getDoctors(specialty: specialty);
      return rows.map((r) => Doctor(
        id: r['id'] as String,
        name: r['name'] as String,
        specialty: r['specialty'] as String,
        hospital: r['hospital'] as String? ?? '',
        experienceYears: (r['experience_years'] as num?)?.toInt() ?? 10,
        rating: ((r['rating'] as num?) ?? 4.8).toDouble(),
        reviewsCount: (r['reviews_count'] as num?)?.toInt() ?? 50,
        consultationFee: ((r['consultation_fee'] as num?) ?? 500).toDouble(),
        availableDays: List<String>.from(r['available_days'] ?? ['Mon', 'Wed', 'Fri']),
        timeSlots: List<String>.from(r['time_slots'] ?? ['10:00 AM', '02:00 PM']),
        imageUrl: r['image_url'] as String? ?? '',
        bio: r['bio'] as String? ?? '',
      )).toList();
    } catch (_) {
      return _fallback.getDoctors(specialty: specialty);
    }
  }

  @override
  Future<Doctor?> getDoctorById(String doctorId) async {
    try {
      final row = await _client.from('doctors').select().eq('id', doctorId).maybeSingle();
      if (row == null) return await _fallback.getDoctorById(doctorId);
      return Doctor(
        id: row['id'] as String,
        name: row['name'] as String,
        specialty: row['specialty'] as String,
        hospital: row['hospital'] as String? ?? '',
        experienceYears: (row['experience_years'] as num?)?.toInt() ?? 10,
        rating: ((row['rating'] as num?) ?? 4.8).toDouble(),
        reviewsCount: (row['reviews_count'] as num?)?.toInt() ?? 50,
        consultationFee: ((row['consultation_fee'] as num?) ?? 500).toDouble(),
        availableDays: List<String>.from(row['available_days'] ?? ['Mon', 'Wed', 'Fri']),
        timeSlots: List<String>.from(row['time_slots'] ?? ['10:00 AM', '02:00 PM']),
        imageUrl: row['image_url'] as String? ?? '',
        bio: row['bio'] as String? ?? '',
      );
    } catch (_) {
      return _fallback.getDoctorById(doctorId);
    }
  }

  @override
  Future<List<DoctorAppointment>> getDoctorAppointments() async {
    try {
      final rows = await _client.from('doctor_appointments').select().order('created_at', ascending: false);
      if (rows.isEmpty) return await _fallback.getDoctorAppointments();
      return rows.map((r) => DoctorAppointment(
        id: r['id'] as String,
        doctorId: r['doctor_id'] as String,
        doctorName: r['doctor_name'] as String,
        specialty: r['specialty'] as String,
        hospital: r['hospital'] as String? ?? '',
        date: DateTime.parse(r['appointment_date'] as String),
        timeSlot: r['time_slot'] as String,
        consultationType: r['consultation_type'] as String? ?? 'homeVisit',
        status: r['status'] as String? ?? 'confirmed',
        patientName: r['patient_name'] as String? ?? 'Senior',
        notes: r['notes'] as String?,
      )).toList();
    } catch (_) {
      return _fallback.getDoctorAppointments();
    }
  }

  @override
  Future<DoctorAppointment> bookDoctorAppointment(DoctorAppointment appointment) async {
    try {
      await _client.from('doctor_appointments').insert({
        'id': appointment.id,
        'doctor_id': appointment.doctorId,
        'doctor_name': appointment.doctorName,
        'specialty': appointment.specialty,
        'hospital': appointment.hospital,
        'appointment_date': appointment.date.toIso8601String(),
        'time_slot': appointment.timeSlot,
        'consultation_type': appointment.consultationType,
        'status': appointment.status,
        'patient_name': appointment.patientName,
        'notes': appointment.notes,
      });
      return appointment;
    } catch (_) {
      return _fallback.bookDoctorAppointment(appointment);
    }
  }

  @override
  Future<List<Caregiver>> getCaregivers() async {
    try {
      final rows = await _client.from('caregivers').select();
      if (rows.isEmpty) return await _fallback.getCaregivers();
      return rows.map((r) => Caregiver(
        id: r['id'] as String,
        name: r['name'] as String,
        rating: ((r['rating'] as num?) ?? 4.8).toDouble(),
        reviewsCount: (r['reviews_count'] as num?)?.toInt() ?? 40,
        hourlyRate: ((r['hourly_rate'] as num?) ?? 250).toDouble(),
        experienceYears: (r['experience_years'] as num?)?.toInt() ?? 5,
        isVerified: (r['is_verified'] as bool?) ?? true,
        imageUrl: r['image_url'] as String? ?? '',
        specialties: List<String>.from(r['specialties'] ?? ['Elderly Care']),
        bio: r['bio'] as String? ?? '',
      )).toList();
    } catch (_) {
      return _fallback.getCaregivers();
    }
  }

  @override
  Future<Caregiver?> getCaregiverById(String caregiverId) async {
    return _fallback.getCaregiverById(caregiverId);
  }

  @override
  Future<List<CaregiverBookingRecord>> getCaregiverBookings() async {
    return _fallback.getCaregiverBookings();
  }

  @override
  Future<CaregiverBookingRecord> bookCaregiver(CaregiverBookingRecord booking) async {
    return _fallback.bookCaregiver(booking);
  }
}
