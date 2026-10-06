import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../../../data/mock/partner_seed.dart';
import '../data/mock_partner_auth_repository.dart';
import '../domain/partner_auth_repository.dart';

final partnerAuthRepositoryProvider = Provider<PartnerAuthRepository>((ref) {
  if (useMockData) {
    final repo = MockPartnerAuthRepository(
      ref.watch(sharedPreferencesProvider),
    );
    ref.onDispose(repo.dispose);
    return repo;
  }
  final repo = MockPartnerAuthRepository(ref.watch(sharedPreferencesProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final partnerAuthStateProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(partnerAuthRepositoryProvider);
  return repo.watchAuthState();
});

final partnerWorkerProfileProvider = Provider<PartnerWorkerProfile>((ref) {
  return PartnerSeed.worker;
});
