import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../../../data/mock/partner_seed.dart';
import '../data/firebase_partner_auth_repository.dart';
import '../data/mock_partner_auth_repository.dart';
import '../domain/partner_auth_repository.dart';

/// Sample sign-in for demos and tests; Firebase when the live build has
/// Firebase options (the session, and the person row in Supabase).
final partnerAuthRepositoryProvider = Provider<PartnerAuthRepository>((ref) {
  final PartnerAuthRepository repo = useMockData || !FirebaseBootstrap.isReady
      ? MockPartnerAuthRepository(ref.watch(sharedPreferencesProvider))
      : FirebasePartnerAuthRepository();
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
