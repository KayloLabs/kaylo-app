import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/core/services/location_service.dart';
import 'package:kaylo/features/profile/presentation/screens/saved_addresses_screen.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('saved addresses list the seed and add one from GPS',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.addresses,
      routes: [
        GoRoute(
          path: Routes.addresses,
          builder: (_, _) => const SavedAddressesScreen(),
        ),
      ],
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
      ],
    ));
    await settle(tester);

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Default'), findsOneWidget);

    await tester.tap(find.text('Add address'));
    await settle(tester);
    await tester.tap(find.text('Farm'));
    await tester.pump();
    await tester.tap(find.text('Use my location'));
    await settle(tester);
    expect(find.text('Fort Road, Kannur, Kannur, 670001'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('Address saved'), findsOneWidget);
    expect(find.text('Farm'), findsOneWidget);
    expect(find.text('Fort Road, Kannur, Kannur, 670001'), findsOneWidget);
    expect(find.byIcon(Icons.agriculture_rounded), findsOneWidget);
  });
}
