import 'dart:async';
import 'dart:convert';

import 'package:kaylo_core/models/app_user.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../domain/auth_repository.dart';

/// Demo sign-in with no backend: any phone number with code 1234, or a
/// fixed Google identity. The identity is persisted so a reload keeps
/// the same name, and profile edits stick.
class MockAuthRepository implements AuthRepository {
  final StorageService _storage;
  final _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;
  String? _pendingDisplayName;

  static const demoUser = AppUser(
    id: 'mock_uid_1',
    firstName: 'Nimal',
    lastName: 'User',
    phone: '+91 9847012345',
  );

  static const googleDemoUser = AppUser(
    id: 'mock_uid_google',
    firstName: 'Nimal',
    lastName: 'Danyath',
    phone: '',
    email: 'nimal.danyath@example.com',
  );

  MockAuthRepository(this._storage) {
    // Start unauthenticated initially
    _authStateController.add(null);
    _checkPersistedSession();
  }

  Future<void> _checkPersistedSession() async {
    final token = await _storage.getToken();
    if (token == null) return;
    final saved = await _storage.getUserProfile();
    AppUser user = demoUser;
    if (saved != null) {
      try {
        user = AppUser.fromJson(jsonDecode(saved) as Map<String, dynamic>);
      } catch (_) {}
    }
    _currentUser = user;
    _authStateController.add(user);
  }

  Future<void> _signIn(AppUser user) async {
    _currentUser = user;
    _authStateController.add(user);
    await _storage.saveToken('mock_token');
    await _storage.saveUserProfile(jsonEncode(user.toJson()));
  }

  @override
  Stream<AppUser?> get authStateChanges => _authStateController.stream;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<void> signInWithPhone(String phone, {String? displayName}) async {
    if (displayName != null && displayName.trim().isNotEmpty) {
      _pendingDisplayName = displayName.trim();
    }
    await Future.delayed(const Duration(seconds: 1));
    // Simulate OTP sent successfully
  }

  @override
  Future<void> verifyOtp(String phone, String otp) async {
    await Future.delayed(const Duration(seconds: 1));
    if (otp != '1234') {
      throw Exception('Invalid OTP. Use 1234 for testing.');
    }
    final name = _pendingDisplayName;
    _pendingDisplayName = null;
    await _signIn(
      name == null
          ? demoUser.copyWith(phone: phone)
          : AppUser.fromFullName(id: demoUser.id, fullName: name, phone: phone),
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
    await _signIn(googleDemoUser);
  }

  @override
  Future<void> signInWithApple() async {
    await Future.delayed(const Duration(seconds: 1));
    await _signIn(const AppUser(
      id: 'mock_uid_apple',
      firstName: 'Apple',
      lastName: 'User',
      phone: '+91 8888888888',
      email: 'apple.user@example.com',
    ));
  }

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final user = _currentUser;
    if (user == null) throw Exception('Sign in first.');
    await Future.delayed(const Duration(milliseconds: 300));
    final updated = user.copyWith(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
    );
    _currentUser = updated;
    _authStateController.add(updated);
    await _storage.saveUserProfile(jsonEncode(updated.toJson()));
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = null;
    _authStateController.add(null);
    await _storage.removeToken();
    await _storage.removeUserProfile();
  }
}
