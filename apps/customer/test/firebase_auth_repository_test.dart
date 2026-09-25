import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/auth/data/firebase_auth_repository.dart';
import 'package:kaylo/features/auth/domain/profile_store.dart';
import 'package:kaylo_core/models/app_user.dart';

void main() {
  test('phone OTP through Firebase creates the profile with the sign-up name',
      () async {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(uid: 'fb-phone', phoneNumber: '+916282374586'),
    );
    final store = InMemoryProfileStore();
    final repo = FirebaseAuthRepository(auth: auth, profiles: store);
    final emitted = <AppUser?>[];
    repo.authStateChanges.listen(emitted.add);

    await repo.signInWithPhone('+916282374586', displayName: 'Anjali Menon');
    await repo.verifyOtp('+916282374586', '123456');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final user = repo.currentUser!;
    expect(user.firstName, 'Anjali');
    expect(user.phone, '+916282374586');
    expect(await store.findByAuthId('fb-phone'), user);
    expect(emitted.last, user);
  });

  test('Google sign-in maps the Google identity onto the profile', () async {
    final auth = MockFirebaseAuth(
      mockUser: MockUser(
        uid: 'fb-google',
        displayName: 'Ruthwik Nair',
        email: 'ruthwik@example.com',
        photoURL: 'https://example.com/r.png',
      ),
    );
    final store = InMemoryProfileStore();
    final repo = FirebaseAuthRepository(
      auth: auth,
      profiles: store,
      googleIdToken: () async => 'fake-google-id-token',
    );

    await repo.signInWithGoogle();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final user = repo.currentUser!;
    expect(user.fullName, 'Ruthwik Nair');
    expect(user.email, 'ruthwik@example.com');
    expect(user.profileImageUrl, 'https://example.com/r.png');
    expect(user.contactLine, 'ruthwik@example.com');
  });

  test('renaming updates the store and re-emits the user', () async {
    final auth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: 'fb-edit', displayName: 'Old Name'),
    );
    final store = InMemoryProfileStore();
    final repo = FirebaseAuthRepository(auth: auth, profiles: store);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(repo.currentUser?.fullName, 'Old Name');

    final emitted = <AppUser?>[];
    repo.authStateChanges.listen(emitted.add);
    await repo.updateProfile(firstName: 'New', lastName: 'Name');

    expect(repo.currentUser?.fullName, 'New Name');
    expect((await store.findByAuthId('fb-edit'))?.fullName, 'New Name');
    expect(emitted.last?.fullName, 'New Name');
    expect(auth.currentUser?.displayName, 'New Name');
  });

  test('Firebase error codes become messages the screen can show', () {
    String describe(String code, [String? message]) =>
        describeFirebaseAuthError(
            FirebaseAuthException(code: code, message: message));

    expect(describe('invalid-verification-code'), contains('code is not right'));
    expect(describe('session-expired'), contains('expired'));
    expect(describe('popup-closed-by-user'), 'Sign-in cancelled.');
    expect(describe('operation-not-allowed'), contains('not enabled'));
    expect(describe('something-new', 'Raw message'), 'Raw message');
    expect(describe('something-new'), contains('try again'));
  });

  test('verifying without requesting a code first is refused clearly',
      () async {
    final repo = FirebaseAuthRepository(
      auth: MockFirebaseAuth(mockUser: MockUser(uid: 'x')),
      profiles: InMemoryProfileStore(),
    );
    expect(
      () => repo.verifyOtp('+919847012345', '000000'),
      throwsA(predicate((e) => e.toString().contains('Request a new code'))),
    );
  });
}
