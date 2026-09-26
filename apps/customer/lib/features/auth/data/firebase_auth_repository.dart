import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/auth_repository.dart';
import '../domain/profile_store.dart';

/// Sign-in through Firebase Authentication: phone OTP, Google, Apple
/// (web). The profile row lives in Supabase, which trusts the Firebase
/// ID token (see supabase/migrations/0005), so the rest of the app is
/// unchanged.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final ProfileSync _profiles;

  /// Gets a Google ID token on Android and iOS. Injected so tests can
  /// bypass the google_sign_in plugin.
  final Future<String?> Function() _googleIdToken;

  final _controller = StreamController<AppUser?>.broadcast();
  StreamSubscription<User?>? _subscription;
  AppUser? _currentUser;

  /// Mobile: the id Firebase hands back once the SMS is sent.
  String? _verificationId;

  /// Web: the pending confirmation (web verifies through reCAPTCHA).
  ConfirmationResult? _webConfirmation;

  /// Name typed on the sign-up form, used when the person row is created.
  String? _pendingDisplayName;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    ProfileStore? profiles,
    Future<String?> Function()? googleIdToken,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _profiles = ProfileSync(
          profiles ?? SupabaseProfileStore(supabase.Supabase.instance.client),
        ),
        _googleIdToken = googleIdToken ?? _googleIdTokenFromPlugin {
    _subscription = _auth.authStateChanges().listen((user) async {
      _currentUser = user == null ? null : await _profileFor(user);
      _controller.add(_currentUser);
    });
  }

  SignInIdentity _identityOf(User user) => SignInIdentity(
        authUserId: user.uid,
        displayName: user.displayName,
        email: user.email,
        phone: user.phoneNumber,
        photoUrl: user.photoURL,
      );

  Future<AppUser> _profileFor(User user) async {
    final identity = _identityOf(user);
    try {
      return await _profiles.resolve(identity, preferredName: _pendingDisplayName);
    } catch (_) {
      // Offline, or the row is not reachable yet: the session still
      // works and the screens show what the provider knows.
      return AppUser.fromFullName(
        id: user.uid,
        fullName: _pendingDisplayName ?? identity.displayName ?? placeholderName,
        phone: identity.phone ?? '',
        email: identity.email,
        profileImageUrl: identity.photoUrl,
      );
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithPhone(String phone, {String? displayName}) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      _pendingDisplayName = displayName.trim();
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
          if (!sent.isCompleted) sent.completeError(AuthMessage(describeFirebaseAuthError(e)));
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
      throw AuthMessage(describeFirebaseAuthError(e));
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
      throw AuthMessage(describeFirebaseAuthError(e));
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
        throw AuthMessage('Google did not return a sign-in token. Try again.');
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(describeFirebaseAuthError(e));
    }
  }

  /// google_sign_in 7: one-time initialize, then an interactive
  /// authenticate that yields the ID token Firebase exchanges.
  static Future<void>? _googleInit;

  static Future<String?> _googleIdTokenFromPlugin() async {
    try {
      _googleInit ??= GoogleSignIn.instance.initialize(
        serverClientId: googleServerClientId.isEmpty ? null : googleServerClientId,
      );
      await _googleInit;
      final account = await GoogleSignIn.instance.authenticate();
      return account.authentication.idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthMessage('Sign-in cancelled.');
      }
      throw AuthMessage(e.description ?? 'Google sign-in failed. Try again.');
    }
  }

  @override
  Future<void> signInWithApple() async {
    if (!kIsWeb) {
      throw AuthMessage(
        'Apple sign-in needs the Apple developer setup; use phone or Google for now.',
      );
    }
    try {
      await _auth.signInWithPopup(AppleAuthProvider()..addScope('email'));
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(describeFirebaseAuthError(e));
    }
  }

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final user = _currentUser;
    if (user == null) throw AuthMessage('Sign in first.');
    final updated = await _profiles.store.update(
      user.copyWith(firstName: firstName.trim(), lastName: lastName.trim()),
    );
    // Keep the Firebase account's display name in step, best effort.
    try {
      await _auth.currentUser?.updateDisplayName(updated.fullName);
    } catch (_) {}
    _currentUser = updated;
    _controller.add(updated);
  }

  @override
  Future<void> signOut() async {
    _verificationId = null;
    _webConfirmation = null;
    _pendingDisplayName = null;
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}

/// Firebase error codes in words the sign-in screens can show as they are.
String describeFirebaseAuthError(FirebaseAuthException e) => switch (e.code) {
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
        'popup-closed-by-user' ||
        'cancelled-popup-request' =>
          'Sign-in cancelled.',
        'popup-blocked' =>
          'The browser blocked the sign-in window. Allow pop-ups and try again.',
        'operation-not-allowed' =>
          'This sign-in method is not enabled for Kaylo yet.',
        'account-exists-with-different-credential' =>
          'This email is already used with another sign-in method.',
        _ => e.message ?? 'Sign-in failed. Please try again.',
      };

/// A sign-in problem in words the screen can show as it is.
class AuthMessage implements Exception {
  final String message;

  AuthMessage(this.message);

  @override
  String toString() => message;
}
