import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:kaylo_core/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/auth_repository.dart';

/// Phone OTP through Firebase Authentication. The profile row still
/// lives in Supabase, which trusts the Firebase ID token (see
/// supabase/migrations/0005), so the rest of the app is unchanged.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final supabase.SupabaseClient _db;
  final _controller = StreamController<AppUser?>.broadcast();
  StreamSubscription<User?>? _subscription;
  AppUser? _currentUser;

  /// Mobile: the id Firebase hands back once the SMS is sent.
  String? _verificationId;

  /// Web: the pending confirmation (web verifies through reCAPTCHA).
  ConfirmationResult? _webConfirmation;

  /// Name typed on the sign-up form, used when the person row is created.
  String? _pendingDisplayName;

  FirebaseAuthRepository({FirebaseAuth? auth, supabase.SupabaseClient? db})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = db ?? supabase.Supabase.instance.client {
    _subscription = _auth.authStateChanges().listen((user) async {
      _currentUser = user == null ? null : await _profileFor(user);
      _controller.add(_currentUser);
    });
  }

  /// The person behind a Firebase user; created on first sign-in so the
  /// customer row exists before the first booking.
  Future<AppUser> _profileFor(User user) async {
    final phone = user.phoneNumber ?? '';
    final name = _pendingDisplayName?.trim();
    final fallback = AppUser(
      id: user.uid,
      firstName: name == null || name.isEmpty ? 'Kaylo' : name,
      lastName: name == null || name.isEmpty ? 'User' : '',
      phone: phone,
    );
    try {
      final row = await _db
          .from('persons')
          .select('person_id, full_name, phone_number, profile_photo')
          .eq('auth_user_id', user.uid)
          .maybeSingle();
      if (row != null) {
        return AppUser(
          id: row['person_id'] as String,
          firstName: row['full_name'] as String,
          lastName: '',
          phone: (row['phone_number'] as String?) ?? phone,
          profileImageUrl: row['profile_photo'] as String?,
        );
      }
      final inserted = await _db
          .from('persons')
          .insert({
            'auth_user_id': user.uid,
            'full_name': name == null || name.isEmpty ? 'Kaylo User' : name,
            'phone_number': phone.isEmpty ? null : phone,
          })
          .select('person_id')
          .single();
      final personId = inserted['person_id'] as String;
      await _db.from('customers').insert({'person_id': personId});
      return fallback.copyWith(id: personId);
    } catch (_) {
      // Offline, or the row exists under another auth id: the session
      // still works, and the profile screen shows what it can.
      return fallback;
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithPhone(String phone, {String? displayName}) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      _pendingDisplayName = displayName;
    }
    try {
      if (kIsWeb) {
        _webConfirmation = await _auth.signInWithPhoneNumber(phone);
        return;
      }
      final sent = Completer<void>();
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // Android read the SMS itself; the OTP screen's stream listener
          // then sees the signed-in user and moves on.
          try {
            await _auth.signInWithCredential(credential);
          } catch (_) {}
          if (!sent.isCompleted) sent.complete();
        },
        verificationFailed: (e) {
          if (!sent.isCompleted) sent.completeError(AuthMessage(_describe(e)));
        },
        codeSent: (verificationId, _) {
          _verificationId = verificationId;
          if (!sent.isCompleted) sent.complete();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
      await sent.future;
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(_describe(e));
    }
  }

  @override
  Future<void> verifyOtp(String phone, String otp) async {
    try {
      if (kIsWeb) {
        final confirmation = _webConfirmation;
        if (confirmation == null) throw AuthMessage('Request a new code first.');
        await confirmation.confirm(otp);
        return;
      }
      final verificationId = _verificationId;
      if (verificationId == null) throw AuthMessage('Request a new code first.');
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: otp,
        ),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(_describe(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    if (!kIsWeb) {
      throw AuthMessage('Google sign-in is not enabled on this device yet.');
    }
    try {
      await _auth.signInWithPopup(GoogleAuthProvider());
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(_describe(e));
    }
  }

  @override
  Future<void> signInWithApple() async {
    throw AuthMessage('Apple sign-in is not enabled yet.');
  }

  @override
  Future<void> signOut() async {
    _verificationId = null;
    _webConfirmation = null;
    _pendingDisplayName = null;
    await _auth.signOut();
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }

  static String _describe(FirebaseAuthException e) => switch (e.code) {
        'invalid-phone-number' => 'That phone number does not look right.',
        'invalid-verification-code' =>
          'That code is not right. Check the SMS and try again.',
        'session-expired' ||
        'code-expired' =>
          'That code has expired. Request a new one.',
        'too-many-requests' =>
          'Too many attempts. Please wait a while and try again.',
        'network-request-failed' =>
          'No connection. Check your network and try again.',
        'quota-exceeded' =>
          'SMS limit reached for today. Please try again later.',
        _ => e.message ?? 'Sign-in failed. Please try again.',
      };
}

/// A sign-in problem in words the screen can show as it is.
class AuthMessage implements Exception {
  final String message;

  AuthMessage(this.message);

  @override
  String toString() => message;
}
