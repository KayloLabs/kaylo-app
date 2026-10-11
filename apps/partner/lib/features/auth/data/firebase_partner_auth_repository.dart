import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../domain/partner_auth_repository.dart';
import 'partner_access_stream.dart';
import '../../notifications/data/partner_push_service.dart';

typedef PartnerStateLoader = Future<Map<String, dynamic>?> Function();
typedef PasswordChangeVerifier = Future<void> Function(String token);

/// Only Kaylo-provisioned credentials may enter this app. This repository
/// never creates a person, worker, role, or customer while signing in.
class FirebasePartnerAuthRepository implements PartnerAuthRepository {
  final FirebaseAuth _auth;
  final PartnerStateLoader _loadState;
  final PasswordChangeVerifier _verifyPasswordChange;
  final Future<void> Function() _clearPushToken;
  final DateTime Function() _now;
  final _state = StreamController<PartnerAccess>.broadcast();
  StreamSubscription<User?>? _subscription;
  PartnerAccess _access = const PartnerAccess(PartnerAccessStatus.signedOut);
  String? _signedInPassword;
  bool _passwordAwaitingConfirmation = false;
  bool _signingIn = false;
  int _generation = 0;
  int _accessCheck = 0;
  Future<PartnerAccess>? _pendingCheck;
  String? _pendingUid;
  String? _checkedUid;
  DateTime? _checkedAt;
  static const _navigationCacheLifetime = Duration(seconds: 15);

  FirebasePartnerAuthRepository({
    FirebaseAuth? auth,
    PartnerStateLoader? loadState,
    PasswordChangeVerifier? verifyPasswordChange,
    Future<void> Function()? clearPushToken,
    DateTime Function()? now,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _loadState = loadState ?? _loadFromSupabase,
       _verifyPasswordChange = verifyPasswordChange ?? _verifyWithBackend,
       _clearPushToken = clearPushToken ?? clearPartnerPushToken,
       _now = now ?? DateTime.now {
    _subscription = _auth.idTokenChanges().listen((user) {
      if (_signingIn) return;
      if (user == null) {
        _generation++;
        _invalidateAccess();
        // Covers SDK-driven expiry/sign-out, where the UI did not call signOut.
        // Explicit signOut already cleared the binding before publishing null.
        if (_access.signedIn) {
          unawaited(_clearPushToken().catchError((Object _) {}));
        }
        _publish(const PartnerAccess(PartnerAccessStatus.signedOut));
      } else {
        // A new ID token may carry a changed issuance or revoked permission.
        unawaited(checkAccess(forceRefresh: true));
      }
    });
  }

  static Future<Map<String, dynamic>?> _loadFromSupabase() async {
    final result = await supabase.Supabase.instance.client.rpc(
      'partner_login_state',
    );
    return result == null ? null : Map<String, dynamic>.from(result as Map);
  }

  static Future<void> _verifyWithBackend(String token) async {
    final result = await supabase.Supabase.instance.client.functions.invoke(
      'partner-password-changed',
      headers: {'Authorization': 'Bearer $token'},
      body: <String, dynamic>{},
    );
    if (result.data is! Map || result.data['ok'] != true) {
      throw const PartnerAuthException(PartnerAuthError.passwordConfirmation);
    }
  }

  void _publish(PartnerAccess access) {
    if (_access == access) return;
    _access = access;
    if (!_state.isClosed) _state.add(access);
  }

  bool _issuedIdentity(User user) {
    final email = user.email?.toLowerCase() ?? '';
    return RegExp(r'^kp-[0-9]{6}@partners\.kaylo\.app$').hasMatch(email) &&
        user.providerData.any((provider) => provider.providerId == 'password');
  }

  @override
  Future<PartnerAccess> checkAccess({bool forceRefresh = false}) {
    final user = _auth.currentUser;
    if (forceRefresh || user == null || _checkedUid != user.uid) {
      _checkedAt = null;
      _checkedUid = null;
    }
    if (!forceRefresh && user != null) {
      final pending = _pendingCheck;
      if (pending != null && _pendingUid == user.uid) return pending;
      final age = _checkedAt == null ? null : _now().difference(_checkedAt!);
      if (_checkedUid == user.uid &&
          age != null &&
          !age.isNegative &&
          age < _navigationCacheLifetime) {
        return Future.value(_access);
      }
    }
    final pending = _checkAccessFromBackend(user);
    _pendingCheck = pending;
    _pendingUid = user?.uid;
    return pending.whenComplete(() {
      if (identical(_pendingCheck, pending)) {
        _pendingCheck = null;
        _pendingUid = null;
      }
    });
  }

  void _invalidateAccess() {
    _checkedUid = null;
    _checkedAt = null;
    _pendingCheck = null;
    _pendingUid = null;
  }

  Future<PartnerAccess> _checkAccessFromBackend(User? user) async {
    final generation = _generation;
    final accessCheck = ++_accessCheck;
    if (user == null) {
      _publish(const PartnerAccess(PartnerAccessStatus.signedOut));
      return _access;
    }
    if (!_issuedIdentity(user)) {
      await signOut();
      return _access;
    }
    try {
      final data = await _loadState().timeout(const Duration(seconds: 15));
      if (_generation != generation ||
          accessCheck != _accessCheck ||
          _auth.currentUser?.uid != user.uid) {
        return _access;
      }
      if (data == null) {
        _publish(const PartnerAccess(PartnerAccessStatus.registration));
      } else {
        final id = data['partner_id'] as String?;
        final workerId = data['worker_id'] as String?;
        if (id == null ||
            workerId == null ||
            partnerEmail(id) != user.email?.toLowerCase()) {
          await signOut();
          return _access;
        }
        final verification = data['verification_status'] as String?;
        // Password state must be explicit: a missing flag never grants access.
        final status = data['must_change_password'] == true
            ? PartnerAccessStatus.passwordChange
            : data['must_change_password'] != false
            ? PartnerAccessStatus.unavailable
            : verification == 'verified'
            ? PartnerAccessStatus.ready
            : PartnerAccessStatus.verification;
        _publish(
          PartnerAccess(
            status,
            partnerId: id,
            workerId: workerId,
            verificationStatus: verification,
          ),
        );
      }
      if (_access.status != PartnerAccessStatus.unavailable) {
        _checkedUid = user.uid;
        _checkedAt = _now();
      }
    } catch (error) {
      if (_generation != generation || accessCheck != _accessCheck) {
        return _access;
      }
      if (error is FirebaseAuthException &&
              [
                'user-disabled',
                'user-token-expired',
                'invalid-user-token',
              ].contains(error.code) ||
          error is supabase.PostgrestException &&
              [
                'PGRST301',
                'PGRST302',
                'PGRST303',
                '28000',
              ].contains(error.code)) {
        await signOut();
      } else {
        _publish(const PartnerAccess(PartnerAccessStatus.unavailable));
      }
    }
    return _access;
  }

  @override
  Future<PartnerAccess> signIn(String partnerId, String password) async {
    final email = partnerEmail(partnerId);
    if (password.isEmpty) {
      throw const PartnerAuthException(PartnerAuthError.invalidCredentials);
    }
    _generation++;
    _invalidateAccess();
    _signingIn = true;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      _signedInPassword = password;
      _passwordAwaitingConfirmation = false;
      final access = await checkAccess(forceRefresh: true);
      if (access.status == PartnerAccessStatus.signedOut) {
        throw const PartnerAuthException(PartnerAuthError.identityNotAllowed);
      }
      return access;
    } on FirebaseAuthException catch (error) {
      throw PartnerAuthException(partnerAuthError(error));
    } finally {
      _signingIn = false;
    }
  }

  @override
  Future<PartnerAccess> changePassword(String password) async {
    final user = _auth.currentUser;
    if (user == null || !_issuedIdentity(user)) {
      throw const PartnerAuthException(PartnerAuthError.sessionExpired);
    }
    if (password.length < 12) {
      throw const PartnerAuthException(PartnerAuthError.weakPassword);
    }
    if (!_passwordAwaitingConfirmation && password == _signedInPassword) {
      throw const PartnerAuthException(PartnerAuthError.differentPassword);
    }
    try {
      if (!_passwordAwaitingConfirmation) {
        await user.updatePassword(password);
        _signedInPassword = null;
        _passwordAwaitingConfirmation = true;
      }
      final token = await user.getIdToken(true);
      if (token == null) {
        throw const PartnerAuthException(PartnerAuthError.sessionExpired);
      }
      await _verifyPasswordChange(token).timeout(const Duration(seconds: 20));
      final access = await checkAccess(forceRefresh: true);
      if (access.status == PartnerAccessStatus.passwordChange ||
          access.status == PartnerAccessStatus.unavailable) {
        throw const PartnerAuthException(PartnerAuthError.passwordConfirmation);
      }
      _passwordAwaitingConfirmation = false;
      return access;
    } on FirebaseAuthException catch (error) {
      throw PartnerAuthException(partnerAuthError(error));
    } on supabase.FunctionException catch (error) {
      if (error.status == 401 || error.status == 403) {
        await signOut();
        throw PartnerAuthException(
          error.status == 401
              ? PartnerAuthError.sessionExpired
              : PartnerAuthError.identityNotAllowed,
        );
      }
      throw const PartnerAuthException(PartnerAuthError.passwordConfirmation);
    } on PartnerAuthException {
      rethrow;
    } catch (_) {
      throw const PartnerAuthException(PartnerAuthError.passwordConfirmation);
    }
  }

  @override
  Future<bool> isAuthenticated() async => (await checkAccess()).signedIn;
  @override
  Stream<PartnerAccess> watchAccess() =>
      watchPartnerAccess(changes: _state.stream, initial: checkAccess);

  @override
  Future<void> signOut() async {
    _generation++;
    _invalidateAccess();
    _signedInPassword = null;
    _passwordAwaitingConfirmation = false;
    try {
      await _clearPushToken();
    } catch (_) {}
    _publish(const PartnerAccess(PartnerAccessStatus.signedOut));
    await _auth.signOut();
  }

  @override
  void dispose() {
    _generation++;
    _invalidateAccess();
    _subscription?.cancel();
    _state.close();
  }
}

PartnerAuthError partnerAuthError(FirebaseAuthException error) =>
    switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' => PartnerAuthError.invalidCredentials,
      'too-many-requests' => PartnerAuthError.tooManyAttempts,
      'network-request-failed' => PartnerAuthError.network,
      'weak-password' ||
      'password-does-not-meet-requirements' => PartnerAuthError.weakPassword,
      'requires-recent-login' ||
      'user-token-expired' ||
      'invalid-user-token' ||
      'user-disabled' => PartnerAuthError.sessionExpired,
      _ => PartnerAuthError.unavailable,
    };
