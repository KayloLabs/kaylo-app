import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/core/router/routes.dart';
import 'package:kaylo_partner/features/onboarding/application/application_document_picker.dart';
import 'package:kaylo_partner/features/onboarding/application/application_providers.dart';
import 'package:kaylo_partner/features/onboarding/data/mock_worker_application_repository.dart';
import 'package:kaylo_partner/features/onboarding/domain/worker_application.dart';
import 'package:kaylo_partner/features/onboarding/presentation/screens/worker_application_screen.dart';
import 'package:kaylo_partner/features/onboarding/presentation/screens/worker_application_status_screen.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:kaylo_ui/widgets/kaylo_text_field.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DocumentPicker implements ApplicationDocumentPicker {
  @override
  Future<ApplicationDocument?> pick(ApplicationDocumentType type) async =>
      ApplicationDocument(
        name: '${type.value}.jpg',
        bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0]),
      );
}

class _DelayedStatusRepository extends MockWorkerApplicationRepository {
  Completer<ApplicationStatus> pending = Completer<ApplicationStatus>();
  final requestedReferences = <String>[];

  @override
  Future<ApplicationStatus> checkStatus(String reference) {
    requestedReferences.add(reference);
    return pending.future;
  }
}

Future<SharedPreferences> pumpApplication(
  WidgetTester tester, {
  MockWorkerApplicationRepository? repository,
  String initialLocation = Routes.apply,
  String locale = 'en',
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.apply,
        builder: (_, _) => const WorkerApplicationScreen(),
      ),
      GoRoute(
        path: Routes.applicationStatus,
        builder: (_, s) => WorkerApplicationStatusScreen(
          initialReference: s.uri.queryParameters['reference'],
        ),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const Scaffold(body: Text('Sign in')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        workerApplicationRepositoryProvider.overrideWithValue(
          repository ?? MockWorkerApplicationRepository(),
        ),
        applicationDocumentPickerProvider.overrideWithValue(_DocumentPicker()),
      ],
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

Future<void> enter(WidgetTester tester, String label, String text) async {
  final field = find.descendant(
    of: find.byWidgetPredicate((w) => w is KayloTextField && w.label == label),
    matching: find.byType(TextFormField),
  );
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

Future<void> tapText(WidgetTester tester, String text) async {
  if (find.text(text).evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      find.text(text),
      250,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final finder = find.text(text).last;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('anonymous form requires delivery email before advancing', (
    tester,
  ) async {
    await pumpApplication(tester);
    await enter(tester, 'Full name', 'Test Applicant');
    await enter(tester, 'Phone number', '9847012345');
    await tapText(tester, 'Continue');
    expect(find.text('Enter a valid delivery email'), findsOneWidget);
    expect(find.text('About you'), findsOneWidget);
    expect(find.text('Your work & service area'), findsNothing);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets(
    'anonymous application requires all documents and consent, then saves reference only',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await pumpApplication(tester);
      await enter(tester, 'Full name', 'Test Applicant');
      await enter(tester, 'Phone number', '9847012345');
      await enter(tester, 'Delivery email', 'applicant@example.test');
      await tapText(tester, 'Continue');
      await enter(tester, 'Profession', 'Electrician');
      await tapText(tester, 'Electrical Services');
      await enter(tester, 'Experience (years)', '3');
      final district = find.byType(DropdownButtonFormField<String>);
      await tester.ensureVisible(district);
      await tester.tap(district);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kannur').last);
      await tester.pumpAndSettle();
      await tapText(tester, 'Continue');
      await tapText(tester, 'Continue');
      expect(find.text('Add all five documents to continue'), findsOneWidget);
      for (final label in [
        'Profile photo',
        'Aadhaar front',
        'Aadhaar back',
        'Police clearance certificate',
        'Selfie',
      ]) {
        await tapText(tester, label);
      }
      await tapText(tester, 'Continue');
      await enter(tester, 'UPI ID', 'test@bank');
      await tapText(tester, 'Submit application');
      expect(
        find.text('Please give consent before submitting'),
        findsOneWidget,
      );
      final consent = find.byType(CheckboxListTile);
      await tester.ensureVisible(consent);
      await tester.tap(consent);
      await tester.pumpAndSettle();
      await tapText(tester, 'Submit application');
      expect(find.text('Application under review'), findsOneWidget);
      expect(find.text('5 of 5 documents received'), findsOneWidget);
      expect(find.text('Test Applicant'), findsNothing);
      expect(prefs.getKeys(), {applicationReferencePreferenceKey});
      expect(
        prefs.getString(applicationReferencePreferenceKey),
        startsWith('KA-DEMO-'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'status lookup shows partial upload honestly and exposes no applicant details',
    (tester) async {
      final repo = MockWorkerApplicationRepository();
      final receipt = await repo.submit(
        const ApplicationDetails(
          fullName: 'Private Name',
          phone: '9847012345',
          email: 'private@example.test',
          profession: 'Electrician',
          services: ['svc-electrical'],
          experienceYears: 3,
          district: 'Kannur',
          travelRadiusKm: 10,
          upiId: 'test@bank',
          consent: true,
        ),
        'a' * 64,
      );
      await pumpApplication(
        tester,
        repository: repo,
        initialLocation:
            '${Routes.applicationStatus}?reference=${receipt.reference}',
      );
      expect(find.text('Documents still needed'), findsOneWidget);
      expect(find.text('0 of 5 documents received'), findsOneWidget);
      expect(find.text('Application under review'), findsNothing);
      expect(find.textContaining('Private Name'), findsNothing);
      expect(find.textContaining('private@example.test'), findsNothing);
      await tapText(tester, 'Back to sign in');
      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  for (final returnsError in [false, true]) {
    testWidgets(
      'discard stale status ${returnsError ? "error" : "result"} after editing the reference',
      (tester) async {
        final repo = _DelayedStatusRepository();
        await pumpApplication(
          tester,
          repository: repo,
          initialLocation: Routes.applicationStatus,
        );
        await enter(tester, 'Application reference', 'ka-old000001');
        await tester.tap(
          find.widgetWithText(KayloButton, 'Check application status'),
        );
        await tester.pump();
        expect(repo.requestedReferences, ['KA-OLD000001']);
        await enter(tester, 'Application reference', 'KA-NEW000002');
        if (returnsError) {
          repo.pending.completeError(
            const WorkerApplicationFailure(ApplicationFailureCode.notFound),
          );
        } else {
          repo.pending.complete(
            const ApplicationStatus(
              reference: 'KA-OLD000001',
              stage: WorkerApplicationStage.approved,
              documentsReceived: 5,
            ),
          );
        }
        await tester.pumpAndSettle();
        expect(find.text('Application approved'), findsNothing);
        expect(
          find.text(
            'No application matches that reference. Check the reference and try again.',
          ),
          findsNothing,
        );

        repo.pending = Completer<ApplicationStatus>();
        await tester.tap(
          find.widgetWithText(KayloButton, 'Check application status'),
        );
        await tester.pump();
        repo.pending.complete(
          const ApplicationStatus(
            reference: 'KA-NEW000002',
            stage: WorkerApplicationStage.underReview,
            documentsReceived: 5,
          ),
        );
        await tester.pumpAndSettle();
        expect(repo.requestedReferences, ['KA-OLD000001', 'KA-NEW000002']);
        expect(find.text('Application under review'), findsOneWidget);
        await enter(tester, 'Application reference', 'KA-THIRD00003');
        expect(find.text('Application under review'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in ['hi', 'ml', 'ta']) {
    testWidgets('application layout supports $locale on a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpApplication(tester, locale: locale);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.text('Apply to Kaylo'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
