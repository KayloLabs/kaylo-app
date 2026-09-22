import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/models/app_user.dart';
import '../data/mock_auth_repository.dart';
import 'package:kaylo_core/services/storage_service.dart';
import '../data/supabase_auth_repository.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  Future<void> signInWithPhone(String phone);
  Future<void> verifyOtp(String phone, String otp);

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();

  Future<void> signOut();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMockData) {
    return MockAuthRepository(ref.watch(storageServiceProvider));
  }
  return SupabaseAuthRepository();
});
