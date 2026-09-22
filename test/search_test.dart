import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/home/application/search_controller.dart';
import 'package:kaylo/features/home/presentation/screens/search_screen.dart';

import 'support/test_app.dart';

List<RouteBase> _routes({
  String initialQuery = '',
  SearchFilters? initialFilters,
}) => [
  GoRoute(
    path: Routes.search,
    builder: (_, _) => SearchScreen(
      initialQuery: initialQuery,
      initialFilters: initialFilters,
    ),
  ),
  stubRoute(Routes.serviceDetails, 'home-details-stub'),
  stubRoute('/farm/:serviceId', 'farm-details-stub'),
  stubRoute(Routes.workerProfile, 'worker-stub'),
];

void main() {
  testWidgets('opens on recent and popular searches, not stale results', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.search, routes: _routes()),
    );
    await settle(tester);

    expect(find.text('Popular searches'), findsOneWidget);
    expect(find.text('Services (15)'), findsNothing);
  });

  testWidgets('typing finds services by name and by plain language', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.search, routes: _routes()),
    );
    await settle(tester);

    await tester.enterText(find.byType(TextFormField), 'tap is leaking');
    await settle(tester);

    expect(find.text('Services (1)'), findsOneWidget);
    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Coconut Plucking'), findsNothing);
  });

  testWidgets('a name query lists professionals from the workers list', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.search, routes: _routes()),
    );
    await settle(tester);

    await tester.enterText(find.byType(TextFormField), 'raju');
    await settle(tester);

    expect(find.text('Professionals (1)'), findsOneWidget);
    expect(find.text('Raju K.'), findsOneWidget);

    await tester.tap(find.text('Raju K.'));
    await settle(tester);
    expect(find.text('worker-stub'), findsOneWidget);
  });

  testWidgets('a category chip on its own browses that category', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.search, routes: _routes()),
    );
    await settle(tester);

    await tester.tap(find.text('Farm'));
    await settle(tester);

    expect(find.text('Coconut Plucking'), findsOneWidget);
    expect(find.text('Tree Pruning'), findsOneWidget);
    expect(find.text('Plumbing'), findsNothing);
    expect(find.text('More'), findsNothing, reason: 'not a bookable service');

    await tester.tap(find.text('Coconut Plucking'));
    await settle(tester);
    expect(find.text('farm-details-stub'), findsOneWidget);
  });

  testWidgets('the tune button hands over filters and a sort order', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: Routes.search,
        routes: _routes(
          initialFilters: (category: 'home', sort: SearchSort.priceLowHigh),
        ),
      ),
    );
    await settle(tester);

    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Coconut Plucking'), findsNothing);
    expect(find.byType(InputChip), findsOneWidget, reason: 'sort chip');

    // Cheapest home service first.
    final electrical = tester.getTopLeft(find.text('Electrical'));
    final plumbing = tester.getTopLeft(find.text('Plumbing'));
    expect(electrical.dy, lessThan(plumbing.dy));
  });

  testWidgets('no match explains itself; a hero deep link searches', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: Routes.search,
        routes: _routes(initialQuery: 'plumb'),
      ),
    );
    await settle(tester);
    expect(find.text('Plumbing'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'zzzz');
    await settle(tester);
    expect(find.textContaining('"zzzz"'), findsOneWidget);
    expect(find.textContaining('tap is leaking'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'clean');
    await settle(tester);
    await tester.tap(find.text('House Cleaning'));
    await settle(tester);
    expect(find.text('home-details-stub'), findsOneWidget);
  });
}
