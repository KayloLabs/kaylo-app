import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../data/mock_availability_repository.dart';
import '../data/supabase_availability_repository.dart';
import '../domain/availability.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final AvailabilityRepository repo = useMockData || !FirebaseBootstrap.isReady
      ? MockAvailabilityRepository(ref.watch(sharedPreferencesProvider))
      : SupabaseAvailabilityRepository(ref.watch(supabaseClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

/// Null until the worker has saved any hours (then they are bookable at
/// any time).
final weeklyHoursProvider = StreamProvider<WeeklyHours?>((ref) {
  return ref.watch(availabilityRepositoryProvider).watchWeeklyHours();
});

final timeOffProvider = StreamProvider<List<TimeOff>>((ref) {
  return ref.watch(availabilityRepositoryProvider).watchTimeOff();
});
