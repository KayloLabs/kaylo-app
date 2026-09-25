import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/auth/domain/profile_store.dart';
import 'package:kaylo_core/models/app_user.dart';

void main() {
  late InMemoryProfileStore store;
  late ProfileSync sync;

  setUp(() {
    store = InMemoryProfileStore();
    sync = ProfileSync(store);
  });

  test('a first phone sign-in creates the person with the sign-up name',
      () async {
    final user = await sync.resolve(
      const SignInIdentity(authUserId: 'fb-1', phone: '+916282374586'),
      preferredName: 'Anjali Menon',
    );

    expect(user.id, isNotEmpty);
    expect(user.firstName, 'Anjali');
    expect(user.lastName, 'Menon');
    expect(user.phone, '+916282374586');
    expect(await store.findByAuthId('fb-1'), user);
  });

  test('a bare phone sign-in gets the placeholder name', () async {
    final user = await sync.resolve(
      const SignInIdentity(authUserId: 'fb-2', phone: '+919847012345'),
    );
    expect(user.fullName, placeholderName);
  });

  test('a Google sign-in carries name, email and photo into the profile',
      () async {
    final user = await sync.resolve(const SignInIdentity(
      authUserId: 'fb-3',
      displayName: 'Ruthwik Nair',
      email: 'ruthwik@example.com',
      photoUrl: 'https://example.com/r.png',
    ));

    expect(user.firstName, 'Ruthwik');
    expect(user.lastName, 'Nair');
    expect(user.email, 'ruthwik@example.com');
    expect(user.profileImageUrl, 'https://example.com/r.png');
    expect(user.phone, isEmpty);
  });

  test('a richer sign-in fills what the existing row is missing',
      () async {
    final first = await sync.resolve(
      const SignInIdentity(authUserId: 'fb-4', phone: '+919847000000'),
    );
    expect(first.fullName, placeholderName);

    final again = await sync.resolve(const SignInIdentity(
      authUserId: 'fb-4',
      displayName: 'Suma P',
      email: 'suma@example.com',
      photoUrl: 'https://example.com/s.png',
    ));

    expect(again.id, first.id, reason: 'same person row');
    expect(again.fullName, 'Suma P');
    expect(again.email, 'suma@example.com');
    expect(again.profileImageUrl, 'https://example.com/s.png');
    expect(again.phone, '+919847000000', reason: 'phone kept');
  });

  test('a name the customer chose is never overwritten by a provider',
      () async {
    final created = await sync.resolve(
      const SignInIdentity(authUserId: 'fb-5'),
      preferredName: 'Chosen Name',
    );
    await store.update(created.copyWith(firstName: 'Edited'));

    final again = await sync.resolve(const SignInIdentity(
      authUserId: 'fb-5',
      displayName: 'Google Name',
    ));

    expect(again.firstName, 'Edited');
  });

  test('AppUser splits and rejoins names and picks a contact line', () {
    expect(AppUser.splitName('  Nimal Danyath K '), ('Nimal', 'Danyath K'));
    expect(AppUser.splitName('Nimal'), ('Nimal', ''));
    expect(AppUser.splitName(''), ('', ''));
    const withPhone = AppUser(
        id: 'a', firstName: 'A', lastName: 'B', phone: '+91 1', email: 'a@b');
    const noPhone = AppUser(
        id: 'a', firstName: 'A', lastName: 'B', phone: '', email: 'a@b');
    expect(withPhone.contactLine, '+91 1');
    expect(noPhone.contactLine, 'a@b');
    expect(AppUser.fromJson(withPhone.toJson()), withPhone);
  });
}
