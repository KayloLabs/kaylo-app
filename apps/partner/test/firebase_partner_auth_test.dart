import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/auth/profile_store.dart';
import 'package:kaylo_partner/features/auth/data/firebase_partner_auth_repository.dart';

void main() {
  test('ten-digit Indian numbers get +91; full numbers are kept', () {
    expect(
      FirebasePartnerAuthRepository.normalisePhone('98470 12345'),
      '+919847012345',
    );
    expect(
      FirebasePartnerAuthRepository.normalisePhone('+91 98470 12345'),
      '+919847012345',
    );
    expect(
      FirebasePartnerAuthRepository.normalisePhone('919847012345'),
      '+919847012345',
    );
  });

  test(
    'phone OTP through Firebase signs the worker in and makes a person, not a customer',
    () async {
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'fb-worker', phoneNumber: '+919847012345'),
      );
      final store = InMemoryProfileStore(createsCustomer: false);
      final repo = FirebasePartnerAuthRepository(auth: auth, profiles: store);
      final states = <bool>[];
      repo.watchAuthState().listen(states.add);

      expect(await repo.isAuthenticated(), isFalse);
      expect(await repo.sendOtp('98470 12345'), isTrue);
      expect(await repo.verifyOtp('98470 12345', '123456'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(await repo.isAuthenticated(), isTrue);
      expect(states.last, isTrue);
      final person = await store.findByAuthId('fb-worker');
      expect(person, isNotNull);
      expect(person!.phone, '+919847012345');
      expect(store.customerIds, isEmpty, reason: 'workers get no customer row');

      await repo.signOut();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await repo.isAuthenticated(), isFalse);
      expect(states.last, isFalse);
      repo.dispose();
    },
  );
}
