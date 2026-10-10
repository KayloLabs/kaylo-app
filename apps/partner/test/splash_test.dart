import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/storage_service.dart';
import 'package:kaylo_partner/core/router/app_router.dart';
import 'package:kaylo_partner/features/jobs/application/jobs_providers.dart';
import 'package:kaylo_partner/features/splash/presentation/screens/partner_splash_screen.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The partner app from its first route, with sample data. The container is
/// returned so a test can shut the sample jobs timer down before the leak
/// check runs.
Future<({ProviderContainer container, Widget app})> _app({
  required bool signedIn,
}) async {
  SharedPreferences.setMockInitialValues({
    if (signedIn) 'kaylo_partner_issued_session': 'KP-000123',
    if (signedIn) 'kaylo_partner_password_changed': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  final app = UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      theme: AppTheme.lightTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: container.read(partnerRouterProvider),
    ),
  );
  return (container: container, app: app);
}

/// Stops the sample jobs timer and disposes the container inside the test
/// body, before flutter_test checks for pending timers.
Future<void> _shutDown(WidgetTester tester, ProviderContainer container) async {
  await container.read(jobsRepositoryProvider).setDuty(false);
  await tester.pumpWidget(const SizedBox.shrink());
  container.dispose();
}

void main() {
  testWidgets('the splash plays, then a signed-out worker lands on sign-in', (
    tester,
  ) async {
    final harness = await _app(signedIn: false);
    await tester.pumpWidget(harness.app);
    await tester.pump();
    expect(find.byType(PartnerSplashScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Kaylo Partner'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(PartnerSplashScreen), findsNothing);
    expect(find.text('Sign in'), findsWidgets);
    await _shutDown(tester, harness.container);
  });

  testWidgets('a signed-in worker goes straight to Jobs', (tester) async {
    final harness = await _app(signedIn: true);
    await tester.pumpWidget(harness.app);
    await tester.pumpAndSettle();
    expect(find.byType(PartnerSplashScreen), findsNothing);
    expect(find.text('Sign in'), findsNothing);
    await _shutDown(tester, harness.container);
  });

  testWidgets('reduced motion shows the finished mark and moves on', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final harness = await _app(signedIn: false);
    await tester.pumpWidget(harness.app);
    // The router resolves its first redirect after a microtask, so the
    // splash mounts on the second frame; with no animation to pump, the
    // short hold then needs explicit time before the hand-off.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);
    await _shutDown(tester, harness.container);
  });
}
