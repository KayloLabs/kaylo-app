import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/core/router/app_router.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/earnings/presentation/screens/earnings_screen.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, Widget)> createHarness() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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

void main() {
  testWidgets('switching offline hides the request feed', (tester) async {
    final (container, app) = await createHarness();
    addTearDown(() async {
      await container.read(jobsRepositoryProvider).setDuty(false);
      container.dispose();
    });
    await tester.pumpWidget(app);
    await signIn(tester);
    expect(find.text('New Requests (2)'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.text("You're Offline"), findsWidgets);
    expect(find.text('New Requests (2)'), findsNothing);
  });

  testWidgets('accepting a request moves it into the active job banner', (
    tester,
  ) async {
    final (container, app) = await createHarness();
    addTearDown(() async {
      await container.read(jobsRepositoryProvider).setDuty(false);
      container.dispose();
    });
    await tester.pumpWidget(app);
    await signIn(tester);

    await container.read(jobsRepositoryProvider).acceptJob('job-req-1');
    await tester.pumpAndSettle();

    expect(find.text('Active Job'), findsOneWidget);
    expect(find.text('Electrical Wiring'), findsWidgets);
    await container.read(jobsRepositoryProvider).setDuty(false);
  });

  testWidgets('completing a job adds it to earnings history', (tester) async {
    // The completed-jobs list is sorted by schedule time, so where this job
    // lands depends on the time of day. A surface that keeps the default
    // 800 px width but is much taller builds every row, so the test does not
    // depend on the clock (CI runs in UTC).
    tester.view.physicalSize = const Size(2400, 12000);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    final (container, app) = await createHarness();
    addTearDown(() async {
      await container.read(jobsRepositoryProvider).setDuty(false);
      container.dispose();
    });
    await tester.pumpWidget(app);
    await signIn(tester);

    final repo = container.read(jobsRepositoryProvider);
    await repo.acceptJob('job-req-1');
    for (var i = 0; i < 4; i++) {
      await repo.advanceJob('job-req-1');
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Earnings'));
    await tester.pumpAndSettle();

    expect(find.byType(EarningsScreen), findsOneWidget);
    expect(find.text('Electrical Wiring'), findsOneWidget);
    await repo.setDuty(false);
  });
}
