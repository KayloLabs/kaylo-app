import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/auth/data/firebase_partner_auth_repository.dart';
import 'package:kaylo_partner/features/auth/domain/partner_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class _PasswordInfo extends Fake implements UserInfo {
  @override
  String get providerId => 'password';
}

class _RecordingAuth extends MockFirebaseAuth {
  _RecordingAuth({required super.mockUser});
  String? lastEmail;
  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    lastEmail = email;
    return super.signInWithEmailAndPassword(email: email, password: password);
  }
}

MockUser _worker() => MockUser(
  uid: 'fb-issued-worker',
  email: 'kp-000123@partners.kaylo.app',
  providerData: [_PasswordInfo()],
);
Map<String, dynamic> _state({
  bool mustChange = true,
  String verification = 'verified',
}) => {
  'partner_id': 'KP-000123',
  'worker_id': 'worker-123',
  'person_id': 'person-123',
  'must_change_password': mustChange,
  'verification_status': verification,
};

void main() {
  test(
    'partner ID has a strict issued format and maps to a synthetic email',
    () {
      expect(partnerEmail(' kp-000123 '), 'kp-000123@partners.kaylo.app');
      for (final invalid in [
        '9847012345',
        'user@gmail.com',
        'KP-123',
        'KP-1234567',
        'KP-12345A',
        'KP-123456@other.com',
      ]) {
        expect(
          () => partnerEmail(invalid),
          throwsA(isA<PartnerAuthException>()),
        );
      }
    },
  );

  test(
    'issued email login requires backend worker and first password change',
    () async {
      final auth = _RecordingAuth(mockUser: _worker());
      var current = _state();
      var confirmed = 0;
      var pushClearedBeforeSignOut = false;
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        loadState: () async => current,
        verifyPasswordChange: (token) async {
          expect(token, isNotEmpty);
          confirmed++;
          current = _state(mustChange: false);
        },
        clearPushToken: () async {
          pushClearedBeforeSignOut = auth.currentUser != null;
        },
      );
      addTearDown(repo.dispose);
      final states = <PartnerAccess>[];
      final subscription = repo.watchAccess().listen(states.add);
      addTearDown(subscription.cancel);
      expect(await repo.isAuthenticated(), isFalse);
      final signedIn = await repo.signIn('KP-000123', 'temporaryPassword123');
      expect(auth.lastEmail, 'kp-000123@partners.kaylo.app');
      expect(signedIn.status, PartnerAccessStatus.passwordChange);
      expect(signedIn.canWork, isFalse);
      expect(
        (await repo.changePassword('NewKayloPassword123!')).status,
        PartnerAccessStatus.ready,
      );
      expect(confirmed, 1);
      await repo.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(pushClearedBeforeSignOut, isTrue);
      expect(auth.currentUser, isNull);
      expect(states.last.status, PartnerAccessStatus.signedOut);
    },
  );

  test(
    'password update does not unlock app until server confirms it',
    () async {
      final auth = MockFirebaseAuth(mockUser: _worker());
      var verified = false;
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        loadState: () async => _state(mustChange: !verified),
        verifyPasswordChange: (_) async {
          if (!verified) throw StateError('backend unavailable');
        },
      );
      addTearDown(repo.dispose);
      await repo.signIn('KP-000123', 'temporaryPassword123');
      await expectLater(
        repo.changePassword('NewKayloPassword123!'),
        throwsA(isA<PartnerAuthException>()),
      );
      expect(
        (await repo.checkAccess()).status,
        PartnerAccessStatus.passwordChange,
      );
      verified = true;
      expect(
        (await repo.changePassword('NewKayloPassword123!')).status,
        PartnerAccessStatus.ready,
      );
    },
  );

  test('the temporary password cannot be retained', () async {
    final auth = MockFirebaseAuth(mockUser: _worker());
    final repo = FirebasePartnerAuthRepository(
      auth: auth,
      loadState: () async => _state(),
    );
    addTearDown(repo.dispose);
    await repo.signIn('KP-000123', 'temporaryPassword123');
    await expectLater(
      repo.changePassword('temporaryPassword123'),
      throwsA(
        isA<PartnerAuthException>().having(
          (e) => e.code,
          'code',
          PartnerAuthError.differentPassword,
        ),
      ),
    );
  });

  test('customer and phone-only Firebase sessions are signed out', () async {
    for (final user in [
      MockUser(email: 'customer@example.com', providerData: [_PasswordInfo()]),
      MockUser(
        email: 'kp-000123@partners.kaylo.app',
        phoneNumber: '+919847012345',
      ),
    ]) {
      final auth = MockFirebaseAuth(mockUser: user, signedIn: true);
      var loads = 0;
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        loadState: () async {
          loads++;
          return _state(mustChange: false);
        },
      );
      expect((await repo.checkAccess()).status, PartnerAccessStatus.signedOut);
      expect(auth.currentUser, isNull);
      expect(loads, 0);
      repo.dispose();
    }
  });

  test(
    'missing worker is registration-only; rejected worker cannot work',
    () async {
      for (final data in [
        null,
        _state(mustChange: false, verification: 'rejected'),
        _state(mustChange: false, verification: 'submitted'),
      ]) {
        final auth = MockFirebaseAuth(mockUser: _worker());
        final repo = FirebasePartnerAuthRepository(
          auth: auth,
          loadState: () async => data,
        );
        final access = await repo.signIn('KP-000123', 'temporaryPassword123');
        expect(
          access.status,
          data == null
              ? PartnerAccessStatus.registration
              : PartnerAccessStatus.verification,
        );
        expect(access.canWork, isFalse);
        repo.dispose();
      }
    },
  );

  test('backend outage or missing password flag fails closed', () async {
    final auth = MockFirebaseAuth(mockUser: _worker());
    final repo = FirebasePartnerAuthRepository(
      auth: auth,
      loadState: () async => throw StateError('offline'),
    );
    addTearDown(repo.dispose);
    expect(
      (await repo.signIn('KP-000123', 'temporaryPassword123')).status,
      PartnerAccessStatus.unavailable,
    );
    final missingFlag = FirebasePartnerAuthRepository(
      auth: auth,
      loadState: () async => _state()..remove('must_change_password'),
    );
    addTearDown(missingFlag.dispose);
    expect(
      (await missingFlag.checkAccess()).status,
      PartnerAccessStatus.unavailable,
    );
  });

  test(
    'expired backend session is signed out instead of opening jobs',
    () async {
      final auth = MockFirebaseAuth(mockUser: _worker());
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        loadState: () async => throw const supabase.PostgrestException(
          message: 'expired',
          code: 'PGRST301',
        ),
      );
      addTearDown(repo.dispose);
      await expectLater(
        repo.signIn('KP-000123', 'temporaryPassword123'),
        throwsA(isA<PartnerAuthException>()),
      );
      expect(auth.currentUser, isNull);
      expect((await repo.checkAccess()).canWork, isFalse);
    },
  );

  test(
    'a late backend response cannot restore access after sign-out',
    () async {
      final auth = MockFirebaseAuth(mockUser: _worker());
      Completer<Map<String, dynamic>?>? pending;
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        loadState: () async =>
            pending == null ? _state(mustChange: false) : await pending.future,
      );
      addTearDown(repo.dispose);
      await repo.signIn('KP-000123', 'temporaryPassword123');
      await Future<void>.delayed(Duration.zero);
      pending = Completer();
      final loading = repo.checkAccess(forceRefresh: true);
      await repo.signOut();
      pending.complete(_state(mustChange: false));
      expect((await loading).status, PartnerAccessStatus.signedOut);
    },
  );

  test(
    'a stale verified result cannot overwrite a newer restriction',
    () async {
      final auth = MockFirebaseAuth(mockUser: _worker());
      final pending = <Completer<Map<String, dynamic>?>>[];
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        loadState: () async => pending.isEmpty
            ? _state(mustChange: false)
            : await pending.removeAt(0).future,
      );
      addTearDown(repo.dispose);
      await repo.signIn('KP-000123', 'temporaryPassword123');
      await Future<void>.delayed(Duration.zero);
      final old = Completer<Map<String, dynamic>?>();
      final recent = Completer<Map<String, dynamic>?>();
      pending.addAll([old, recent]);
      final first = repo.checkAccess(forceRefresh: true);
      final second = repo.checkAccess(forceRefresh: true);
      recent.complete(_state(mustChange: false, verification: 'rejected'));
      expect((await second).status, PartnerAccessStatus.verification);
      old.complete(_state(mustChange: false));
      expect((await first).status, PartnerAccessStatus.verification);
    },
  );

  test('password confirmation with an expired session signs out', () async {
    final auth = MockFirebaseAuth(mockUser: _worker());
    final repo = FirebasePartnerAuthRepository(
      auth: auth,
      loadState: () async => _state(),
      verifyPasswordChange: (_) async => throw const supabase.FunctionException(
        status: 401,
        details: {
          'error': {'message': 'SIGN_IN_AGAIN'},
        },
      ),
    );
    addTearDown(repo.dispose);
    await repo.signIn('KP-000123', 'temporaryPassword123');
    await expectLater(
      repo.changePassword('NewKayloPassword123!'),
      throwsA(
        isA<PartnerAuthException>().having(
          (e) => e.code,
          'code',
          PartnerAuthError.sessionExpired,
        ),
      ),
    );
    expect(auth.currentUser, isNull);
  });

  test(
    'navigation reuses a recent access result and shares expired lookups',
    () async {
      final auth = MockFirebaseAuth(mockUser: _worker());
      var now = DateTime(2026, 10, 10);
      var loads = 0;
      Completer<Map<String, dynamic>?>? pending;
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        now: () => now,
        loadState: () async {
          loads++;
          return pending == null
              ? _state(mustChange: false)
              : await pending.future;
        },
      );
      addTearDown(repo.dispose);
      await repo.signIn('KP-000123', 'temporaryPassword123');
      await Future<void>.delayed(Duration.zero);
      final initialLoads = loads;
      final cached = await Future.wait([
        repo.checkAccess(),
        repo.checkAccess(),
      ]);
      expect(cached.every((access) => access.canWork), isTrue);
      expect(loads, initialLoads);
      now = now.add(const Duration(seconds: 15));
      pending = Completer();
      final first = repo.checkAccess();
      final second = repo.checkAccess();
      expect(loads, initialLoads + 1);
      pending.complete(_state(mustChange: false, verification: 'rejected'));
      expect((await first).status, PartnerAccessStatus.verification);
      expect((await second).status, PartnerAccessStatus.verification);
    },
  );

  test(
    'forced access refresh bypasses cached permissions and password gate',
    () async {
      final auth = MockFirebaseAuth(mockUser: _worker());
      var current = _state(mustChange: false);
      var loads = 0;
      final repo = FirebasePartnerAuthRepository(
        auth: auth,
        loadState: () async {
          loads++;
          return current;
        },
      );
      addTearDown(repo.dispose);
      await repo.signIn('KP-000123', 'temporaryPassword123');
      await Future<void>.delayed(Duration.zero);
      final initialLoads = loads;
      current = _state(mustChange: true);
      expect(
        (await repo.checkAccess(forceRefresh: true)).status,
        PartnerAccessStatus.passwordChange,
      );
      expect(loads, initialLoads + 1);
      expect((await repo.checkAccess()).canWork, isFalse);
    },
  );

  test('a failed refresh fails closed and is immediately retryable', () async {
    final auth = MockFirebaseAuth(mockUser: _worker());
    var offline = false;
    var loads = 0;
    final repo = FirebasePartnerAuthRepository(
      auth: auth,
      loadState: () async {
        loads++;
        if (offline) throw StateError('offline');
        return _state(mustChange: false);
      },
    );
    addTearDown(repo.dispose);
    await repo.signIn('KP-000123', 'temporaryPassword123');
    await Future<void>.delayed(Duration.zero);
    offline = true;
    expect(
      (await repo.checkAccess(forceRefresh: true)).status,
      PartnerAccessStatus.unavailable,
    );
    final failedLoads = loads;
    offline = false;
    expect((await repo.checkAccess()).canWork, isTrue);
    expect(loads, failedLoads + 1);
  });

  test('unknown Firebase messages map to a safe localized error code', () {
    expect(
      partnerAuthError(
        FirebaseAuthException(code: 'internal', message: 'secret diagnostic'),
      ),
      PartnerAuthError.unavailable,
    );
    expect(
      partnerAuthError(FirebaseAuthException(code: 'wrong-password')),
      PartnerAuthError.invalidCredentials,
    );
    expect(
      partnerAuthError(FirebaseAuthException(code: 'network-request-failed')),
      PartnerAuthError.network,
    );
  });
}
