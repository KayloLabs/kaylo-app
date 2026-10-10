import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/models/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/auth_repository.dart';
import 'package:kaylo_core/auth/profile_store.dart';

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
  Object? _sessionFailure;
  int _sessionGeneration = 0;

  /// Calls the email-otp Edge Function with a JSON body and returns its
  /// JSON reply. Injected so tests can bypass the network.
  final Future<Map<String, dynamic>> Function(Map<String, dynamic> body)
  _emailCodes;

  /// Name and phone typed on the sign-up form, used when the person row
  /// is created (an email sign-in carries no phone of its own).
  String? _pendingDisplayName;
  String? _pendingPhone;
  bool _pendingSignUp = false;

  /// Phone sign-in. Mobile: the id Firebase hands back once the SMS is
  /// sent. Web: the pending confirmation (web verifies through reCAPTCHA).
  String? _verificationId;
  ConfirmationResult? _webConfirmation;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    ProfileStore? profiles,
    Future<String?> Function()? googleIdToken,
    Future<Map<String, dynamic>> Function(Map<String, dynamic> body)?
    emailCodes,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _profiles = ProfileSync(
         profiles ?? SupabaseProfileStore(supabase.Supabase.instance.client),
       ),
       _googleIdToken = googleIdToken ?? _googleIdTokenFromPlugin,
       _emailCodes = emailCodes ?? _invokeEmailOtp {
    _subscription = _auth.authStateChanges().listen((user) async {
      if (_controller.isClosed) return;
      final generation = ++_sessionGeneration;
      if (user == null) {
        _currentUser = null;
        if (_sessionFailure != null) {
          _controller.addError(_sessionFailure!);
        } else {
          _controller.add(null);
        }
        return;
      }
      try {
        final profile = await _profileFor(user);
        if (generation != _sessionGeneration || _controller.isClosed) return;
        _currentUser = profile;
        _sessionFailure = null;
        _controller.add(profile);
      } catch (error) {
        if (generation != _sessionGeneration || _controller.isClosed) return;
        _currentUser = null;
        _sessionFailure = error is PartnerAccountNotAllowed
            ? error
            : const CustomerProfileUnavailable();
        await _auth.signOut();
      }
    });
  }

  SignInIdentity _identityOf(User user) => SignInIdentity(
    authUserId: user.uid,
    displayName: user.displayName,
    email: user.email,
    phone: user.phoneNumber ?? _pendingPhone,
    photoUrl: user.photoURL,
  );

  Future<AppUser> _profileFor(User user) async {
    final identity = _identityOf(user);
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        return await _profiles.resolve(
          identity,
          preferredName: _pendingDisplayName,
        );
      } on PartnerAccountNotAllowed {
        rethrow;
      } catch (e) {
        debugPrint(
          'Kaylo: profile sync attempt $attempt failed (${e.runtimeType})',
        );
        if (attempt == 1) {
          await Future<void>.delayed(const Duration(milliseconds: 800));
        }
      }
    }
    throw const CustomerProfileUnavailable();
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

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
    if (phone != null && phone.trim().isNotEmpty) _pendingPhone = phone.trim();
    _pendingSignUp = signUp;
    await _emailCodes({
      'action': 'send',
      'email': email.trim().toLowerCase(),
      'purpose': signUp ? 'signup' : 'signin',
      if (_pendingDisplayName != null) 'name': _pendingDisplayName,
    });
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    _sessionFailure = null;
    if (isPartnerLoginEmail(email)) throw const PartnerAccountNotAllowed();
    final reply = await _emailCodes({
      'action': 'verify',
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
      'purpose': _pendingSignUp ? 'signup' : 'signin',
      if (_pendingDisplayName != null) 'name': _pendingDisplayName,
    });
    final token = reply['token'];
    if (token is! String || token.isEmpty) {
      throw AuthMessage('The sign-in service gave no session. Try again.');
    }
    try {
      // The function found or created the Firebase user for this email;
      // from here on it is an ordinary Firebase session.
      await _auth.signInWithCustomToken(token);
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(describeFirebaseAuthError(e));
    }
  }

  @override
  Future<void> signInWithPhone(String phone, {String? displayName}) async {
    _sessionFailure = null;
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
          if (!sent.isCompleted) {
            sent.completeError(AuthMessage(describeFirebaseAuthError(e)));
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
    } on FirebaseAuthException catch (e) {
      throw AuthMessage(describeFirebaseAuthError(e));
    }
  }

  @override
  Future<void> verifyOtp(String phone, String otp) async {
    try {
      if (kIsWeb) {
        final confirmation = _webConfirmation;
        if (confirmation == null) {
          throw AuthMessage('Request a new code first.');
        }
        await confirmation.confirm(otp);
        return;
      }
      final verificationId = _verificationId;
      if (verificationId == null) {
        throw AuthMessage('Request a new code first.');
      }
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
    _sessionFailure = null;
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
        serverClientId: googleServerClientId.isEmpty
            ? null
            : googleServerClientId,
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
    _sessionFailure = null;
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
    _sessionFailure = null;
    _verificationId = null;
    _webConfirmation = null;
    _pendingDisplayName = null;
    _pendingPhone = null;
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
  'account-exists-with-different-credential' =>
    'This email is already used with another sign-in method.',
  _ => e.message ?? 'Sign-in failed. Please try again.',
};

/// A sign-in problem in words the screen can show as it is.
/// The email-otp Edge Function through the Supabase client. Its error
/// replies carry `{error: {code, message}}`; the message is shown as is.
Future<Map<String, dynamic>> _invokeEmailOtp(Map<String, dynamic> body) async {
  try {
    final res = await supabase.Supabase.instance.client.functions.invoke(
      'email-otp',
      body: body,
    );
    return (res.data as Map).cast<String, dynamic>();
  } on supabase.FunctionException catch (e) {
    final details = e.details;
    if (details is Map && details['error'] is Map) {
      final message = (details['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) throw AuthMessage(message);
    }
    throw AuthMessage(
      'Could not reach the sign-in service (${e.status}). Try again.',
    );
  }
}

class AuthMessage implements Exception {
  final String message;

  AuthMessage(this.message);

  @override
  String toString() => message;
}
