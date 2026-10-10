import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kaylo_core/auth/profile_store.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/partner_auth_repository.dart';

/// Worker sign-in through Firebase Authentication: phone OTP and Google.
/// The person row lives in Supabase, which trusts the Firebase ID token
/// (migration 0005). No customer row is created for a worker; the worker
/// row comes from registration (`register_worker`).
class FirebasePartnerAuthRepository implements PartnerAuthRepository {
  final FirebaseAuth _auth;
  final ProfileSync _profiles;
  final Future<String?> Function() _googleIdToken;

  final _state = StreamController<bool>.broadcast();
  StreamSubscription<User?>? _subscription;
  bool _signedIn = false;

  /// Mobile: the id Firebase hands back once the SMS is sent.
  /// Web: the pending confirmation (web verifies through reCAPTCHA).
  String? _verificationId;
  ConfirmationResult? _webConfirmation;

  FirebasePartnerAuthRepository({
    FirebaseAuth? auth,
    ProfileStore? profiles,
    Future<String?> Function()? googleIdToken,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _profiles = ProfileSync(
         profiles ??
             SupabaseProfileStore(
               supabase.Supabase.instance.client,
               createsCustomer: false,
             ),
       ),
       _googleIdToken = googleIdToken ?? _googleIdTokenFromPlugin {
    _signedIn = _auth.currentUser != null;
    _subscription = _auth.authStateChanges().listen((user) async {
      if (user != null) await _syncProfile(user);
      _signedIn = user != null;
      _state.add(_signedIn);
    });
  }

  Future<void> _syncProfile(User user) async {
    final identity = SignInIdentity(
      authUserId: user.uid,
      displayName: user.displayName,
      email: user.email,
      phone: user.phoneNumber,
      photoUrl: user.photoURL,
    );
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await _profiles.resolve(identity);
        return;
      } catch (e) {
        debugPrint('Kaylo Partner: profile sync attempt $attempt failed: $e');
        if (attempt == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        }
      }
    }
  }

  /// Indian numbers typed as ten digits become +91 numbers; anything that
  /// already carries a country code is kept.
  static String normalisePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('+')) return cleaned;
    if (cleaned.length == 10) return '+91$cleaned';
    if (cleaned.length == 12 && cleaned.startsWith('91')) return '+$cleaned';
    return '+$cleaned';
  }

  @override
  Future<bool> sendOtp(String phone) async {
    final number = normalisePhone(phone);
    try {
      if (kIsWeb) {
        _webConfirmation = await _auth.signInWithPhoneNumber(number);
        return true;
      }
      final sent = Completer<void>();
      await _auth.verifyPhoneNumber(
        phoneNumber: number,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // Android read the SMS itself.
          try {
            await _auth.signInWithCredential(credential);
          } catch (_) {}
          if (!sent.isCompleted) sent.complete();
        },
        verificationFailed: (e) {
          if (!sent.isCompleted) {
            sent.completeError(PartnerAuthMessage(describePartnerAuthError(e)));
          }
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
      return true;
    } on FirebaseAuthException catch (e) {
      throw PartnerAuthMessage(describePartnerAuthError(e));
    }
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    try {
      if (kIsWeb) {
        final confirmation = _webConfirmation;
        if (confirmation == null) {
          throw PartnerAuthMessage('Request a new code first.');
        }
        await confirmation.confirm(code.trim());
        return true;
      }
      final verificationId = _verificationId;
      if (verificationId == null) {
        throw PartnerAuthMessage('Request a new code first.');
      }
      await _auth.signInWithCredential(
        PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: code.trim(),
        ),
      );
      return true;
    } on FirebaseAuthException catch (e) {
      throw PartnerAuthMessage(describePartnerAuthError(e));
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        await _auth.signInWithPopup(GoogleAuthProvider()..addScope('email'));
        return;
      }
      final idToken = await _googleIdToken();
      if (idToken == null) {
        throw PartnerAuthMessage(
          'Google did not return a sign-in token. Try again.',
        );
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on FirebaseAuthException catch (e) {
      throw PartnerAuthMessage(describePartnerAuthError(e));
    }
  }

  static Future<void>? _googleInit;

  static Future<String?> _googleIdTokenFromPlugin() async {
    try {
      _googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: googleServerClientId.isEmpty
            ? null
            : googleServerClientId,
      );
      await _googleInit;
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw PartnerAuthMessage('Sign-in cancelled.');
      }
      throw PartnerAuthMessage(
        e.description ?? 'Google sign-in failed. Try again.',
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async => _auth.currentUser != null;

  @override
  Stream<bool> watchAuthState() async* {
    yield _signedIn;
    yield* _state.stream;
  }

  @override
  Future<void> signOut() async {
    _verificationId = null;
    _webConfirmation = null;
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _state.close();
  }
}

/// Firebase error codes in words the sign-in screen can show as they are.
String describePartnerAuthError(FirebaseAuthException e) => switch (e.code) {
  'invalid-phone-number' => 'That phone number does not look right.',
  'invalid-verification-code' =>
    'That code is not right. Check the SMS and try again.',
  'session-expired' ||
  'code-expired' => 'That code has expired. Request a new one.',
  'too-many-requests' =>
    'Too many attempts. Please wait a while and try again.',
  'network-request-failed' =>
    'No connection. Check your network and try again.',
  'quota-exceeded' => 'SMS limit reached for today. Please try again later.',
  'popup-closed-by-user' || 'cancelled-popup-request' => 'Sign-in cancelled.',
  'popup-blocked' =>
    'The browser blocked the sign-in window. Allow pop-ups and try again.',
  'operation-not-allowed' =>
    'This sign-in method is not enabled for Kaylo yet.',
  _ => e.message ?? 'Sign-in failed. Please try again.',
};
