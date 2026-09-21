import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/services/application/search_providers.dart';
import 'package:kaylo/features/services/presentation/screens/search_screen.dart';

import 'support/test_app.dart';

List<RouteBase> _routes({SearchQuery initial = emptySearch}) => [
      GoRoute(
        path: Routes.search,
        builder: (_, _) => SearchScreen(initial: initial),
      ),
      stubRoute('/service/:serviceId', 'details-stub'),
    ];

void main() {
  testWidgets('an empty query browses the whole catalog', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.search,
      routes: _routes(),
    ));
    await settle(tester);

    expect(find.text('All services'), findsOneWidget);
    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Coconut Plucking'), findsOneWidget);
    expect(find.text('More'), findsNothing, reason: 'not a bookable service');
  });

  testWidgets('typing filters by name and understands plain language',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.search,
      routes: _routes(),
    ));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField), 'tap is leaking');
    await settle(tester);

    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('Coconut Plucking'), findsNothing);
    expect(find.text('1 result for "tap is leaking"'), findsOneWidget);
  });

  testWidgets('category chips narrow the results', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.search,
      routes: _routes(),
    ));
    await settle(tester);

    await tester.tap(find.text('Farm'));
    await settle(tester);

    expect(find.text('Coconut Plucking'), findsOneWidget);
    expect(find.text('Plumbing'), findsNothing);
  });

  testWidgets('no match shows guidance and a result opens details',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.search,
      routes: _routes(),
    ));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField), 'zzzz');
    await settle(tester);
    expect(find.text('No services match'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'coconut');
    await settle(tester);
    await tester.tap(find.text('Coconut Plucking'));
    await settle(tester);
    expect(find.text('details-stub'), findsOneWidget);
  });
}
