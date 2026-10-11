import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/core/router/app_router.dart';
import 'package:kaylo_partner/core/router/routes.dart';
import 'package:kaylo_partner/features/auth/data/mock_partner_auth_repository.dart';
import 'package:kaylo_partner/features/auth/data/partner_access_stream.dart';
import 'package:kaylo_partner/features/auth/application/partner_session.dart';
import 'package:kaylo_partner/features/profile/application/profile_providers.dart';
import 'package:kaylo_partner/features/availability/application/availability_providers.dart';
import 'package:kaylo_partner/features/auth/domain/partner_auth_repository.dart';
import 'package:kaylo_partner/features/auth/presentation/screens/change_password_screen.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SwitchableAuth extends MockPartnerAuthRepository {
  final changes = StreamController<PartnerAccess>.broadcast();
  PartnerAccess access = const PartnerAccess(
    PartnerAccessStatus.ready,
    workerId: 'worker-a',
  );
  @override
  Future<PartnerAccess> checkAccess({bool forceRefresh = false}) async =>
      access;
  @override
  Stream<PartnerAccess> watchAccess() =>
      watchPartnerAccess(changes: changes.stream, initial: () => access);

  void setAccess(PartnerAccess next) {
    access = next;
    changes.add(next);
  }

  @override
  void dispose() {
    changes.close();
    super.dispose();
  }
}

void main() {
  test(
    'profile and schedule caches reset when issued identity changes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final auth = _SwitchableAuth();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          partnerAuthRepositoryProvider.overrideWithValue(auth),
        ],
      );
      addTearDown(() {
        container.dispose();
        auth.dispose();
      });
      final profileSubscription = container.listen(
        workerProfileRepositoryProvider,
        (_, _) {},
      );
      final scheduleSubscription = container.listen(
        availabilityRepositoryProvider,
        (_, _) {},
      );
      addTearDown(profileSubscription.close);
      addTearDown(scheduleSubscription.close);
      await container.read(partnerAuthStateProvider.future);
      await container.pump();
      final firstProfile = container.read(workerProfileRepositoryProvider);
      final firstSchedule = container.read(availabilityRepositoryProvider);
      expect(auth.changes.hasListener, isTrue);
      auth.setAccess(
        const PartnerAccess(PartnerAccessStatus.ready, workerId: 'worker-b'),
      );
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      expect(
        container.read(partnerAuthStateProvider).asData?.value.workerId,
        'worker-b',
      );
      expect(
        identical(
          container.read(workerProfileRepositoryProvider),
          firstProfile,
        ),
        isFalse,
      );
      expect(
        identical(
          container.read(availabilityRepositoryProvider),
          firstSchedule,
        ),
        isFalse,
      );
      final secondProfile = container.read(workerProfileRepositoryProvider);
      auth.setAccess(const PartnerAccess(PartnerAccessStatus.signedOut));
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      expect(
        identical(
          container.read(workerProfileRepositoryProvider),
          secondProfile,
        ),
        isFalse,
      );
    },
  );
  test('all private deep links enforce first password change', () {
    const access = PartnerAccess(PartnerAccessStatus.passwordChange);
    for (final path in [
      Routes.jobs,
      '/jobs/booking-123',
      Routes.earnings,
      Routes.profile,
      Routes.history,
      Routes.availability,
      Routes.apply,
      Routes.applicationStatus,
      Routes.login,
    ]) {
      expect(
        partnerRedirect(access, path),
        Routes.changePassword,
        reason: path,
      );
    }
    expect(partnerRedirect(access, Routes.changePassword), isNull);
  });
  test('unverified workers get only profile and account support access', () {
    const access = PartnerAccess(
      PartnerAccessStatus.verification,
      verificationStatus: 'rejected',
    );
    expect(partnerRedirect(access, Routes.profile), isNull);
    expect(partnerRedirect(access, Routes.accountStatus), isNull);
    for (final path in [
      Routes.jobs,
      '/jobs/booking-123',
      Routes.earnings,
      Routes.availability,
      Routes.history,
    ]) {
      expect(partnerRedirect(access, path), Routes.accountStatus);
    }
  });
  test('applications are public but cannot grant jobs access', () {
    const signedOut = PartnerAccess(PartnerAccessStatus.signedOut);
    expect(partnerRedirect(signedOut, Routes.apply), isNull);
    expect(partnerRedirect(signedOut, Routes.applicationStatus), isNull);
    expect(partnerRedirect(signedOut, Routes.jobs), Routes.login);
    expect(
      partnerRedirect(
        const PartnerAccess(PartnerAccessStatus.registration),
        Routes.jobs,
      ),
      Routes.accountStatus,
    );
    expect(
      partnerRedirect(
        const PartnerAccess(PartnerAccessStatus.unavailable),
        Routes.jobs,
      ),
      Routes.accountStatus,
    );
  });
  test('old phone-login demo preference never grants issued access', () async {
    SharedPreferences.setMockInitialValues({
      'kaylo_partner_is_authenticated': true,
    });
    final repo = MockPartnerAuthRepository(
      await SharedPreferences.getInstance(),
    );
    addTearDown(repo.dispose);
    expect((await repo.checkAccess()).status, PartnerAccessStatus.signedOut);
    await expectLater(
      repo.signIn('KP-000123', 'wrong-password'),
      throwsA(isA<PartnerAuthException>()),
    );
    expect(
      (await repo.signIn('KP-000123', 'kaylo123')).status,
      PartnerAccessStatus.passwordChange,
    );
  });
  testWidgets(
    'a restored temporary-password session cannot deep link to a job',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'kaylo_partner_issued_session': 'KP-000123',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      final router = container.read(partnerRouterProvider);
      router.go('/jobs/booking-123');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PartnerChangePasswordScreen), findsOneWidget);
      expect(find.text('Set your password'), findsOneWidget);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'NewKayloPassword123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'not-the-same-password',
      );
      await tester.tap(find.text('Save password'));
      await tester.pumpAndSettle();
      expect(find.text('The passwords do not match.'), findsOneWidget);
      expect(find.byType(PartnerChangePasswordScreen), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
