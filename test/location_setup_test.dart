import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/core/services/location_service.dart';
import 'package:kaylo/features/auth/presentation/screens/location_setup_screen.dart';
import 'package:kaylo/features/home/application/user_location_provider.dart';

import 'support/test_app.dart';

// Regression guard: an overlay button on this screen once had an
// unbounded width, which broke hit testing and left every button dead.
final _routes = <RouteBase>[
  GoRoute(
    path: Routes.location,
    builder: (_, _) => const LocationSetupScreen(),
  ),
  stubRoute(Routes.dashboard, 'dashboard-stub'),
];

void main() {
  testWidgets('location screen lays out and Not now goes to the dashboard', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.location, routes: _routes),
    );
    await settle(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Enable location'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);

    await tester.tap(find.text('Not now'));
    await settle(tester);
    expect(find.text('dashboard-stub'), findsOneWidget);
  });

  testWidgets('GPS fills the card and Continue saves the location', (
    tester,
  ) async {
    useTallPhone(tester);
    late ProviderContainer container;
    await tester.pumpWidget(
      await testApp(
        initialLocation: Routes.location,
        routes: [
          GoRoute(
            path: Routes.location,
            builder: (context, _) {
              container = ProviderScope.containerOf(context);
              return const LocationSetupScreen();
            },
          ),
          stubRoute(Routes.dashboard, 'dashboard-stub'),
        ],
        overrides: [
          locationServiceProvider.overrideWithValue(FakeLocationService()),
        ],
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Use my location'));
    await settle(tester);

    expect(find.text('Kannur, Kerala'), findsOneWidget);
    expect(find.text('Fort Road, Kannur, Kannur, 670001'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await settle(tester);

    expect(find.text('dashboard-stub'), findsOneWidget);
    expect(
      container.read(userLocationProvider).addressLine,
      'Fort Road, Kannur, Kannur, 670001',
    );
  });

  testWidgets('blocked permission explains how to fix it', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: Routes.location,
        routes: _routes,
        overrides: [
          locationServiceProvider.overrideWithValue(
            FailingLocationService('denied-forever'),
          ),
        ],
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Use my location'));
    await settle(tester);

    expect(
      find.text(
        'Location is blocked for Kaylo. Allow it in your device settings.',
      ),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsNothing);
  });
}
