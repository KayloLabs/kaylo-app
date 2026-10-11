import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/partner_auth_repository.dart';
import 'partner_access_stream.dart';

/// Explicit sample mode. Old phone-login preferences are deliberately ignored.
class MockPartnerAuthRepository implements PartnerAuthRepository {
  final SharedPreferences? _prefs;
  final _controller = StreamController<PartnerAccess>.broadcast();
  static const sessionKey = 'kaylo_partner_issued_session';
  static const changedKey = 'kaylo_partner_password_changed';
  PartnerAccess _access = const PartnerAccess(PartnerAccessStatus.signedOut);

  MockPartnerAuthRepository([this._prefs]) {
    final id = _prefs?.getString(sessionKey);
    if (id != null && normalizePartnerId(id) != null) {
      _access = PartnerAccess(
        _prefs?.getBool(changedKey) == true
            ? PartnerAccessStatus.ready
            : PartnerAccessStatus.passwordChange,
        partnerId: id,
        workerId: 'sample-worker',
        verificationStatus: 'verified',
      );
    }
  }

  void _publish(PartnerAccess access) {
    _access = access;
    if (!_controller.isClosed) _controller.add(access);
  }

  @override
  Future<PartnerAccess> checkAccess({bool forceRefresh = false}) async =>
      _access;
  @override
  Future<bool> isAuthenticated() async => _access.signedIn;
  @override
  Stream<PartnerAccess> watchAccess() =>
      watchPartnerAccess(changes: _controller.stream, initial: () => _access);

  @override
  Future<PartnerAccess> signIn(String partnerId, String password) async {
    final id = normalizePartnerId(partnerId);
    if (id == null) {
      throw const PartnerAuthException(PartnerAuthError.invalidId);
    }
    if (password != 'kaylo123') {
      throw const PartnerAuthException(PartnerAuthError.invalidCredentials);
    }
    final samePartner = _prefs?.getString(sessionKey) == id;
    final changed = samePartner && _prefs?.getBool(changedKey) == true;
    await _prefs?.setString(sessionKey, id);
    if (!samePartner) await _prefs?.setBool(changedKey, false);
    _publish(
      PartnerAccess(
        changed
            ? PartnerAccessStatus.ready
            : PartnerAccessStatus.passwordChange,
        partnerId: id,
        workerId: 'sample-worker',
        verificationStatus: 'verified',
      ),
    );
    return _access;
  }

  @override
  Future<PartnerAccess> changePassword(String password) async {
    if (!_access.signedIn) {
      throw const PartnerAuthException(PartnerAuthError.sessionExpired);
    }
    if (password.length < 12) {
      throw const PartnerAuthException(PartnerAuthError.weakPassword);
    }
    await _prefs?.setBool(changedKey, true);
    _publish(
      PartnerAccess(
        PartnerAccessStatus.ready,
        partnerId: _access.partnerId,
        workerId: _access.workerId,
        verificationStatus: 'verified',
      ),
    );
    return _access;
  }

  @override
  Future<void> signOut() async {
    await _prefs?.remove(sessionKey);
    await _prefs?.remove(changedKey);
    _publish(const PartnerAccess(PartnerAccessStatus.signedOut));
  }

  @override
  void dispose() => _controller.close();
}
