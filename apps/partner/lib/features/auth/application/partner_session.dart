import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../data/firebase_partner_auth_repository.dart';
import '../data/mock_partner_auth_repository.dart';
import '../domain/partner_auth_repository.dart';

final partnerAuthRepositoryProvider = Provider<PartnerAuthRepository>((ref) {
  final PartnerAuthRepository repo = useMockData
      ? MockPartnerAuthRepository(ref.watch(sharedPreferencesProvider))
      : FirebaseBootstrap.isReady
      ? FirebasePartnerAuthRepository()
      : _UnavailablePartnerAuthRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final partnerAuthStateProvider = StreamProvider<PartnerAccess>((ref) {
  return ref.watch(partnerAuthRepositoryProvider).watchAccess();
});

class _UnavailablePartnerAuthRepository implements PartnerAuthRepository {
  static const access = PartnerAccess(PartnerAccessStatus.unavailable);
  @override
  Future<PartnerAccess> checkAccess() async => access;
  @override
  Future<bool> isAuthenticated() async => false;
  @override
  Stream<PartnerAccess> watchAccess() => Stream.value(access);
  @override
  Future<PartnerAccess> signIn(String partnerId, String password) async =>
      throw const PartnerAuthException(PartnerAuthError.unavailable);
  @override
  Future<PartnerAccess> changePassword(String password) async =>
      throw const PartnerAuthException(PartnerAuthError.unavailable);
  @override
  Future<void> signOut() async {}
  @override
  void dispose() {}
}
