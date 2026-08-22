import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/supabase_providers.dart';
import '../data/mock_workers_repository.dart';
import '../data/supabase_workers_repository.dart';
import '../domain/workers_repository.dart';

final workersRepositoryProvider = Provider<WorkersRepository>((ref) {
  if (useMockData) {
    return MockWorkersRepository();
  }
  return SupabaseWorkersRepository(ref.watch(supabaseClientProvider));
});
