import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/supabase_providers.dart';
import '../data/mock_care_repository.dart';
import '../data/supabase_care_repository.dart';
import '../domain/care_repository.dart';
import '../domain/models/appointment.dart';
import '../domain/models/caregiver.dart';
import '../domain/models/doctor.dart';

final careRepositoryProvider = Provider<CareRepository>((ref) {
  if (useMockData) {
    return MockCareRepository();
  }
  return SupabaseCareRepository(ref.watch(supabaseClientProvider));
});

final doctorsListProvider =
    FutureProvider.family<List<Doctor>, String?>((ref, specialty) async {
  final repo = ref.watch(careRepositoryProvider);
  return repo.getDoctors(specialty: specialty);
});

final doctorDetailProvider =
    FutureProvider.family<Doctor?, String>((ref, doctorId) async {
  final repo = ref.watch(careRepositoryProvider);
  return repo.getDoctorById(doctorId);
});

class DoctorAppointmentsNotifier
    extends AsyncNotifier<List<DoctorAppointment>> {
  @override
  Future<List<DoctorAppointment>> build() async {
    final repo = ref.watch(careRepositoryProvider);
    return repo.getDoctorAppointments();
  }

  Future<void> bookAppointment(DoctorAppointment appointment) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(careRepositoryProvider);
      await repo.bookDoctorAppointment(appointment);
      return repo.getDoctorAppointments();
    });
  }
}

final doctorAppointmentsProvider = AsyncNotifierProvider<
    DoctorAppointmentsNotifier, List<DoctorAppointment>>(
  DoctorAppointmentsNotifier.new,
);

final caregiversListProvider = FutureProvider<List<Caregiver>>((ref) async {
  final repo = ref.watch(careRepositoryProvider);
  return repo.getCaregivers();
});

class CaregiverBookingsNotifier
    extends AsyncNotifier<List<CaregiverBookingRecord>> {
  @override
  Future<List<CaregiverBookingRecord>> build() async {
    final repo = ref.watch(careRepositoryProvider);
    return repo.getCaregiverBookings();
  }

  Future<void> bookCaregiver(CaregiverBookingRecord booking) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(careRepositoryProvider);
      await repo.bookCaregiver(booking);
      return repo.getCaregiverBookings();
    });
  }
}

final caregiverBookingsProvider = AsyncNotifierProvider<
    CaregiverBookingsNotifier, List<CaregiverBookingRecord>>(
  CaregiverBookingsNotifier.new,
);
