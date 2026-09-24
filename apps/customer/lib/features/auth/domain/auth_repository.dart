import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';
import 'package:kaylo_core/models/app_user.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../data/firebase_auth_repository.dart';
import '../data/mock_auth_repository.dart';
import '../data/supabase_auth_repository.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  AppUser? get currentUser;

  /// Sends the OTP. [displayName] is the name typed on the sign-up form,
  /// used when the profile is created after the first successful code.
  Future<void> signInWithPhone(String phone, {String? displayName});
  Future<void> verifyOtp(String phone, String otp);

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();

  Future<void> signOut();
}

/// Mock for demos and tests; otherwise Firebase phone auth when the app
/// has Firebase options, falling back to Supabase's own OTP where it
/// does not (desktop builds, a checkout without config files).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (useMockData) {
    return MockAuthRepository(ref.watch(storageServiceProvider));
  }
  if (FirebaseBootstrap.isReady) {
    return FirebaseAuthRepository();
  }
  return SupabaseAuthRepository();
});
