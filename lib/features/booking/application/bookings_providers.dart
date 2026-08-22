import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/supabase_providers.dart';
import '../data/mock_bookings_repository.dart';
import '../data/supabase_bookings_repository.dart';
import '../domain/bookings_repository.dart';

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  if (useMockData) {
    return MockBookingsRepository();
  }
  return SupabaseBookingsRepository(ref.watch(supabaseClientProvider));
});
