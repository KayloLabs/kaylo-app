import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:kaylo_core/models/app_user.dart';
import '../domain/auth_repository.dart';
import 'package:kaylo_core/auth/profile_store.dart';

/// Supabase's own email OTP and OAuth. The fallback where Firebase is
/// not configured (desktop builds); the profile handling is shared with
/// the Firebase repository through ProfileSync.
class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client = supabase.Supabase.instance.client;
  late final ProfileSync _profiles = ProfileSync(SupabaseProfileStore(_client));
  final _authStateController = StreamController<AppUser?>.broadcast();
  StreamSubscription<supabase.AuthState>? _authStateSubscription;
  AppUser? _currentUser;
  Object? _sessionFailure;
  int _sessionGeneration = 0;
  String? _pendingDisplayName;

  SupabaseAuthRepository() {
    _authStateSubscription = _client.auth.onAuthStateChange.listen((
      data,
    ) async {
      if (_authStateController.isClosed) return;
      final generation = ++_sessionGeneration;
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
          final profile = await _profiles.resolve(
            identity,
            preferredName: _pendingDisplayName,
          );
          if (generation != _sessionGeneration || _authStateController.isClosed) {
            return;
          }
          _currentUser = profile;
          _sessionFailure = null;
        } catch (error) {
          if (generation != _sessionGeneration || _authStateController.isClosed) {
            return;
          }
          _currentUser = null;
          _sessionFailure = error is PartnerAccountNotAllowed
              ? error
              : const CustomerProfileUnavailable();
          await _client.auth.signOut();
          return;
        }
      } else {
        _currentUser = null;
      }
      if (_sessionFailure != null) {
        _authStateController.addError(_sessionFailure!);
      } else {
        _authStateController.add(_currentUser);
      }
    });
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> requestEmailCode(
    String email, {
    bool signUp = false,
    String? displayName,
    String? phone,
  }) async {
    _sessionFailure = null;
    if (isPartnerLoginEmail(email)) throw const PartnerAccountNotAllowed();
    if (displayName != null && displayName.trim().isNotEmpty) {
      _pendingDisplayName = displayName.trim();
    }
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: signUp,
      data: {'full_name': ?displayName, 'phone': ?phone},
    );
  }

  @override
  Future<void> signInWithPhone(String phone, {String? displayName}) async {
    _sessionFailure = null;
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
  Future<void> verifyEmailCode(String email, String code) async {
    _sessionFailure = null;
    if (isPartnerLoginEmail(email)) throw const PartnerAccountNotAllowed();
    await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: supabase.OtpType.email,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    _sessionFailure = null;
    // Requires configuration in Supabase Dashboard
    await _client.auth.signInWithOAuth(supabase.OAuthProvider.google);
  }

  @override
  Future<void> signInWithApple() async {
    _sessionFailure = null;
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
    _sessionFailure = null;
    _pendingDisplayName = null;
    await _client.auth.signOut();
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _authStateController.close();
  }
}
