import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/auth/presentation/screens/location_setup_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';

void main() {
  // Regression guard: the "Pick Manually" overlay button once sat in a
  // Positioned with no horizontal anchors, so its infinite-width SizedBox
  // failed layout and hit testing threw for every tap on the screen —
  // both bottom buttons went completely dead on devices.
  Widget app() {
    final router = GoRouter(
      initialLocation: Routes.location,
      routes: [
        GoRoute(
          path: Routes.location,
          builder: (context, state) => const LocationSetupScreen(),
        ),
        GoRoute(
          path: Routes.dashboard,
          builder: (context, state) =>
              const Scaffold(body: Text('dashboard-stub')),
        ),
      ],
    );
    return ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('location screen lays out without errors', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Enable Location'), findsWidgets);
    expect(find.text('Pick Manually'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
  });

  testWidgets('Not now navigates to the dashboard', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(find.text('dashboard-stub'), findsOneWidget);
  });

  testWidgets('Enable Location navigates to the dashboard', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // The headline and the button share the same label; the button is last.
    await tester.tap(find.text('Enable Location').last);
    await tester.pumpAndSettle();

    expect(find.text('dashboard-stub'), findsOneWidget);
  });
}
