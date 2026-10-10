import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/partner_auth_repository.dart';

class MockPartnerAuthRepository implements PartnerAuthRepository {
  final SharedPreferences? _prefs;
  final _controller = StreamController<bool>.broadcast();

  static const _authKey = 'kaylo_partner_is_authenticated';

  bool _isAuth = false;

  MockPartnerAuthRepository([this._prefs]) {
    final stored = _prefs?.getBool(_authKey);
    if (stored != null) {
      _isAuth = stored;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _isAuth;
  }

  @override
  Stream<bool> watchAuthState() async* {
    yield _isAuth;
    yield* _controller.stream;
  }

  @override
  Future<bool> sendOtp(String phone) async {
    // In mock, always succeed
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (code == '1234') {
      _isAuth = true;
      await _prefs?.setBool(_authKey, true);
      _controller.add(true);
      return true;
    }
    return false;
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _isAuth = true;
    await _prefs?.setBool(_authKey, true);
    _controller.add(true);
  }

  @override
  Future<void> signOut() async {
    _isAuth = false;
    await _prefs?.setBool(_authKey, false);
    _controller.add(false);
  }

  @override
  void dispose() {
    _controller.close();
  }
}
