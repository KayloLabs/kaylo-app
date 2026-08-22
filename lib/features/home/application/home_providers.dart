import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/supabase_providers.dart';
import '../data/mock_home_repository.dart';
import '../data/supabase_home_repository.dart';
import '../domain/home_repository.dart';

export '../../../core/config/app_env.dart' show useMock, useMockData;

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  if (useMockData) {
    return MockHomeRepository();
  }
  return SupabaseHomeRepository(ref.watch(supabaseClientProvider));
});
