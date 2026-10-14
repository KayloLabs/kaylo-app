import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/core/router/app_router.dart';
import 'package:kaylo_partner/data/mock/partner_seed.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/profile/application/profile_providers.dart';
import 'package:kaylo_partner/features/profile/data/mock_worker_profile_repository.dart';
import 'package:kaylo_partner/features/profile/domain/worker_profile.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, Widget)> createHarness({
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(Map.of(prefs));
  final shared = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(shared)],
  );
  final router = container.read(partnerRouterProvider);
  return (
    container,
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
}

Future<void> signIn(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.tap(find.text('Sign in').last);
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).at(0), 'NewKayloPass123!');
  await tester.enterText(find.byType(TextFormField).at(1), 'NewKayloPass123!');
  await tester.tap(find.text('Save password'));
  await tester.pumpAndSettle();
}

/// Stops the mock jobs feed's timer and tears the container down inside
/// the test body, so no timer is pending when the test ends.
Future<void> shutDown(WidgetTester tester, ProviderContainer container) async {
  await container.read(jobsRepositoryProvider).setDuty(false);
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
}

class _FailingProfileRepository extends MockWorkerProfileRepository {
  _FailingProfileRepository([super.prefs]);

  @override
  Future<void> setAvailable(bool available) async {
    throw StateError('offline');
  }
}

void main() {
  group('WorkerProfile', () {
    test('survives a JSON round trip with the RPC key names', () {
      final seed = PartnerSeed.worker;
      final copy = WorkerProfile.fromJson(seed.toJson());
      expect(copy.id, seed.id);
      expect(copy.name, seed.name);
      expect(copy.district, 'Kannur');
      expect(copy.travelRadiusKm, 15);
      expect(copy.services, seed.services);
      expect(copy.verification, VerificationStatus.verified);
      expect(copy.joinedOn, DateTime(2024, 3, 12));
      expect(copy.aadhaarStatus, DocumentStatus.verified);
    });

    test('both Aadhaar sides count as one document', () {
      WorkerProfile withDocs(List<WorkerDocument> docs) => WorkerProfile(
        id: 'w',
        personId: 'p',
        name: 'n',
        phone: '',
        joinedOn: DateTime(2025),
        documents: docs,
      );
      expect(withDocs(const []).aadhaarStatus, isNull);
      expect(
        withDocs(const [
          WorkerDocument(
            type: 'aadhaar_front',
            status: DocumentStatus.verified,
          ),
        ]).aadhaarStatus,
        DocumentStatus.pending,
      );
      expect(
        withDocs(const [
          WorkerDocument(
            type: 'aadhaar_front',
            status: DocumentStatus.verified,
          ),
          WorkerDocument(type: 'aadhaar_back', status: DocumentStatus.rejected),
        ]).aadhaarStatus,
        DocumentStatus.rejected,
      );
    });

    test('an edit only carries the fields that were set', () {
      const edit = WorkerProfileEdit(name: 'New', serviceIds: ['a']);
      expect(edit.toJson(), {
        'full_name': 'New',
        'services': ['a'],
      });
      expect(const WorkerProfileEdit().isEmpty, isTrue);
    });
  });

  group('MockWorkerProfileRepository', () {
    test(
      'edits persist and the duty flag is shared with the jobs feed',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final repo = MockWorkerProfileRepository(prefs);
        addTearDown(repo.dispose);

        final updated = await repo.updateProfile(
          const WorkerProfileEdit(
            name: 'Sunil K.',
            district: 'Kozhikode',
            travelRadiusKm: 20,
            serviceIds: ['svc-ac'],
            upiId: 'sunil@okaxis',
          ),
        );
        expect(updated.name, 'Sunil K.');
        expect(updated.district, 'Kozhikode');
        expect(updated.services.map((s) => s.name), ['AC Service']);
        expect(updated.upiId, 'sunil@okaxis');

        await repo.setAvailable(false);
        expect(prefs.getBool(MockWorkerProfileRepository.dutyKey), isFalse);

        // A fresh repository on the same preferences reads it all back.
        final again = MockWorkerProfileRepository(prefs);
        addTearDown(again.dispose);
        final reloaded = await again.getProfile();
        expect(reloaded!.name, 'Sunil K.');
        expect(reloaded.isAvailable, isFalse);
      },
    );

    test(
      'refuses an empty name, no services and a radius out of range',
      () async {
        final repo = MockWorkerProfileRepository();
        addTearDown(repo.dispose);
        expect(
          () => repo.updateProfile(const WorkerProfileEdit(name: ' ')),
          throwsArgumentError,
        );
        expect(
          () => repo.updateProfile(const WorkerProfileEdit(serviceIds: [])),
          throwsArgumentError,
        );
        expect(
          () =>
              repo.updateProfile(const WorkerProfileEdit(travelRadiusKm: 500)),
          throwsArgumentError,
        );
      },
    );
  });

  testWidgets('the duty switch writes the worker row and the feed together', (
    tester,
  ) async {
    final (container, app) = await createHarness();
    await tester.pumpWidget(app);
    await signIn(tester);

    final profileRepo = container.read(workerProfileRepositoryProvider);
    final jobsRepo = container.read(jobsRepositoryProvider);
    expect(find.text('Sunil Kumar • Kannur'), findsOneWidget);
    expect(find.text('Taking orders in Kannur'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(jobsRepo.isOnline, isFalse);
    expect((await profileRepo.getProfile())!.isAvailable, isFalse);
    await shutDown(tester, container);
  });

  test('a failed row write puts the feed back online', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workerProfileRepositoryProvider.overrideWithValue(
          _FailingProfileRepository(prefs),
        ),
      ],
    );
    final jobs = container.read(jobsRepositoryProvider);
    expect(jobs.isOnline, isTrue);
    await expectLater(
      container.read(dutySwitchProvider).set(false),
      throwsStateError,
    );
    expect(jobs.isOnline, isTrue);
    await jobs.setDuty(false);
    container.dispose();
  });

  testWidgets('the profile tab shows the worker and saves an edit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2400, 9000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final (container, app) = await createHarness();
    await tester.pumpWidget(app);
    await signIn(tester);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();

    expect(find.text('Sunil Kumar'), findsOneWidget);
    expect(find.text('Verified partner'), findsOneWidget);
    expect(find.text('Plumbing Repair'), findsOneWidget);
    expect(find.text('142 reviews'), findsOneWidget);
    expect(find.text('Kannur · 15 km radius'), findsOneWidget);
    expect(find.text('Mon – Sat · 8:00 AM – 7:00 PM'), findsOneWidget);

    await tester.tap(find.text('Edit profile').first);
    await tester.pumpAndSettle();
    expect(find.text('Full name'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'Sunil Kumar'),
      'Sunil Kumar P.',
    );
    await tester.tap(find.text('AC Service'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Profile updated'), findsOneWidget);
    expect(find.text('Sunil Kumar P.'), findsOneWidget);
    expect(find.text('AC Service'), findsOneWidget);
    final saved = await container
        .read(workerProfileRepositoryProvider)
        .getProfile();
    expect(saved!.name, 'Sunil Kumar P.');
    expect(saved.services.map((s) => s.id), contains('svc-ac'));
    await shutDown(tester, container);
  });
}
