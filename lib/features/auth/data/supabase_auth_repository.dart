import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../core/models/app_user.dart';
import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final supabase.SupabaseClient _client = supabase.Supabase.instance.client;
  final _authStateController = StreamController<AppUser?>.broadcast();
  StreamSubscription<supabase.AuthState>? _authStateSubscription;
  AppUser? _currentUser;

  SupabaseAuthRepository() {
    _authStateSubscription = _client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        // Fetch user profile from the persons table. Column names match
        // supabase/migrations/0001_initial_schema.sql: person_id,
        // full_name, phone_number, profile_photo.
        try {
          final response = await _client
              .from('persons')
              .select('person_id, full_name, phone_number, profile_photo')
              .eq('auth_user_id', session.user.id)
              .maybeSingle();

          if (response != null) {
            _currentUser = AppUser(
              id: response['person_id'] as String,
              firstName: response['full_name'] as String,
              lastName: '',
              phone: (response['phone_number'] as String?) ?? '',
              profileImageUrl: response['profile_photo'] as String?,
            );
          } else {
            // User just signed up and row not created yet, or they don't have a profile
            _currentUser = AppUser(
              id: session.user.id,
              firstName: 'New',
              lastName: 'User',
              phone: session.user.phone ?? '',
            );
          }
        } catch (e) {
          // Fallback if db fails
           _currentUser = AppUser(
            id: session.user.id,
            firstName: 'Kaylo',
            lastName: 'User',
            phone: session.user.phone ?? '',
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
  Future<void> signInWithPhone(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
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
    await _client.auth.signInWithOAuth(
      supabase.OAuthProvider.google,
    );
  }

  @override
  Future<void> signInWithApple() async {
    await _client.auth.signInWithOAuth(
      supabase.OAuthProvider.apple,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _authStateController.close();
  }
}
