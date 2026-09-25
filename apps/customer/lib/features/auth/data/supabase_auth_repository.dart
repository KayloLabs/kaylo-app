import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:kaylo_core/models/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/profile_store.dart';

/// Supabase's own phone OTP and OAuth. The fallback where Firebase is
/// not configured (desktop builds); the profile handling is shared with
/// the Firebase repository through ProfileSync.
class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client = supabase.Supabase.instance.client;
  late final ProfileSync _profiles =
      ProfileSync(SupabaseProfileStore(_client));
  final _authStateController = StreamController<AppUser?>.broadcast();
  StreamSubscription<supabase.AuthState>? _authStateSubscription;
  AppUser? _currentUser;
  String? _pendingDisplayName;

  SupabaseAuthRepository() {
    _authStateSubscription = _client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final session = data.session;
      if (session != null) {
        final user = session.user;
        final identity = SignInIdentity(
          authUserId: user.id,
          displayName: user.userMetadata?['full_name'] as String?,
          email: user.email,
          phone: user.phone,
          photoUrl: user.userMetadata?['avatar_url'] as String?,
        );
        try {
          _currentUser = await _profiles.resolve(
            identity,
            preferredName: _pendingDisplayName,
          );
        } catch (_) {
          _currentUser = AppUser.fromFullName(
            id: user.id,
            fullName: _pendingDisplayName ?? identity.displayName ?? placeholderName,
            phone: user.phone ?? '',
            email: user.email,
          );
        }
      } else {
        _currentUser = null;
      }
      _authStateController.add(_currentUser);
    });
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithPhone(String phone, {String? displayName}) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      _pendingDisplayName = displayName.trim();
    }
    await _client.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<void> verifyOtp(String phone, String otp) async {
    await _client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: supabase.OtpType.sms,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    // Requires configuration in Supabase Dashboard
    await _client.auth.signInWithOAuth(supabase.OAuthProvider.google);
  }

  @override
  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(supabase.OAuthProvider.apple);
  }

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Sign in first.');
    final updated = await _profiles.store.update(
      user.copyWith(firstName: firstName.trim(), lastName: lastName.trim()),
    );
    _currentUser = updated;
    _authStateController.add(updated);
  }

  @override
  Future<void> signOut() async {
    _pendingDisplayName = null;
    await _client.auth.signOut();
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _authStateController.close();
  }
}
