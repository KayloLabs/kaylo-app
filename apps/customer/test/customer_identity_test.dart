import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo/features/auth/application/session_controller.dart';
import 'package:kaylo/features/auth/presentation/screens/login_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/auth/data/firebase_auth_repository.dart';
import 'package:kaylo_core/auth/profile_store.dart';
import 'package:kaylo_core/models/app_user.dart';

class _WorkerSession extends SessionController {
  @override
  FutureOr<AppUser?> build() => throw const PartnerAccountNotAllowed();
}

void main() {
  testWidgets(
    'customer login clearly directs rejected worker sessions to Partner',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionControllerProvider.overrideWith(_WorkerSession.new),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'This is a Kaylo Partner account. Please use the Kaylo Partner app.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'a worker cannot gain a customer row or edit their profile on customer sign-in',
    () async {
      final store = InMemoryProfileStore();
      final person = await store.create(
        AppUser.fromFullName(
          id: '',
          fullName: 'Approved Worker',
          phone: '+919847000001',
        ),
        authUserId: 'worker-uid',
      );
      store.customerIds.remove(person.id);
      store.workerIds.add(person.id);
      await expectLater(
        ProfileSync(store).resolve(
          const SignInIdentity(
            authUserId: 'worker-uid',
            displayName: 'Changed Name',
          ),
        ),
        throwsA(isA<PartnerAccountNotAllowed>()),
      );
      expect(store.customerIds, isNot(contains(person.id)));
      expect(
        (await store.findByAuthId('worker-uid'))?.fullName,
        'Approved Worker',
      );
    },
  );

  test('a reserved partner address cannot create a customer profile', () async {
    final store = InMemoryProfileStore();
    await expectLater(
      ProfileSync(store).resolve(
        const SignInIdentity(
          authUserId: 'partner-new',
          email: 'KP-000123@partners.kaylo.app',
        ),
      ),
      throwsA(isA<PartnerAccountNotAllowed>()),
    );
    expect(await store.findByAuthId('partner-new'), isNull);
    expect(store.customerIds, isEmpty);
  });

  for (final email in ['kp-000123@partners.kaylo.app', 'worker@example.com']) {
    test(
      'worker session $email is signed out without exposing a customer identity',
      () async {
        final store = InMemoryProfileStore();
        final person = await store.create(
          AppUser.fromFullName(
            id: '',
            fullName: 'Worker',
            phone: '+919847000002',
          ),
          authUserId: 'worker',
        );
        store.customerIds.remove(person.id);
        store.workerIds.add(person.id);
        final auth = MockFirebaseAuth(
          signedIn: true,
          mockUser: MockUser(uid: 'worker', email: email),
        );
        final repo = FirebaseAuthRepository(auth: auth, profiles: store);
        addTearDown(repo.dispose);
        final errors = <Object>[];
        final users = <AppUser?>[];
        final sub = repo.authStateChanges.listen(
          users.add,
          onError: errors.add,
        );
        addTearDown(sub.cancel);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(auth.currentUser, isNull);
        expect(repo.currentUser, isNull);
        expect(users.whereType<AppUser>(), isEmpty);
        expect(errors, contains(isA<PartnerAccountNotAllowed>()));
        expect(store.customerIds, isEmpty);
      },
    );
  }

  test(
    'reserved partner email never reaches the customer OTP service',
    () async {
      var calls = 0;
      final repo = FirebaseAuthRepository(
        auth: MockFirebaseAuth(),
        profiles: InMemoryProfileStore(),
        emailCodes: (_) async {
          calls++;
          return {};
        },
      );
      addTearDown(repo.dispose);
      await expectLater(
        repo.requestEmailCode('kp-000123@partners.kaylo.app'),
        throwsA(isA<PartnerAccountNotAllowed>()),
      );
      await expectLater(
        repo.verifyEmailCode('kp-000123@partners.kaylo.app', '123456'),
        throwsA(isA<PartnerAccountNotAllowed>()),
      );
      expect(calls, 0);
    },
  );
}
