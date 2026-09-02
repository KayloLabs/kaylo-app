import 'dart:async';
import '../../../core/models/app_user.dart';
import '../../../core/services/storage_service.dart';
import '../domain/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  final StorageService _storage;
  final _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  MockAuthRepository(this._storage) {
    // Start unauthenticated initially
    _authStateController.add(null);
    _checkPersistedSession();
  }

  Future<void> _checkPersistedSession() async {
    final token = await _storage.getToken();
    if (token != null) {
      _currentUser = AppUser(
        id: 'mock_uid',
        firstName: 'Mock',
        lastName: 'User',
        phone: '+91 9999999999',
      );
      _authStateController.add(_currentUser);
    }
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithPhone(String phone) async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulate OTP sent successfully
  }

  @override
  Future<void> verifyOtp(String phone, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp == '1234') {
      _currentUser = AppUser(
        id: 'mock_uid_1',
        firstName: 'Nimal',
        lastName: 'User',
        phone: phone,
      );
      _authStateController.add(_currentUser);
      await _storage.saveToken('mock_token');
    } else {
      throw Exception('Invalid OTP. Use 1234 for testing.');
    }
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AppUser(
      id: 'mock_uid_google',
      firstName: 'Google',
      lastName: 'User',
      phone: '+91 9999999999',
    );
    _authStateController.add(_currentUser);
    await _storage.saveToken('mock_token');
  }

  @override
  Future<void> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = AppUser(
      id: 'mock_uid_apple',
      firstName: 'Apple',
      lastName: 'User',
      phone: '+91 8888888888',
    );
    _authStateController.add(_currentUser);
    await _storage.saveToken('mock_token');
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = null;
    _authStateController.add(null);
    await _storage.removeToken();
  }
}
