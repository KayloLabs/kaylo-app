import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/location_service.dart';
import 'package:kaylo/features/home/application/user_location_provider.dart';
import 'package:kaylo/features/home/presentation/widgets/location_picker_sheet.dart';

import 'support/test_app.dart';

// testApp runs the map with no engine (placeholder, no tiles, no
// platform view); the GPS and search paths are what these cover.
late ProviderContainer container;

List<RouteBase> get _routes => [
  GoRoute(
    path: '/',
    builder: (context, _) {
      container = ProviderScope.containerOf(context);
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => showLocationPickerSheet(context),
            child: const Text('open'),
          ),
        ),
      );
    },
  ),
];

Future<void> _openPicker(WidgetTester tester) async {
  useTallPhone(tester);
  await tester.pumpWidget(
    await testApp(
      initialLocation: '/',
      routes: _routes,
      overrides: [
        locationServiceProvider.overrideWithValue(FakeLocationService()),
      ],
    ),
  );
  await settle(tester);
  await tester.tap(find.text('open'));
  await settle(tester);
}

void main() {
  testWidgets('opens on the current location with Confirm ready', (
    tester,
  ) async {
    await _openPicker(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Your location'), findsOneWidget);
    expect(find.text('Kannur, Kerala'), findsOneWidget);
    expect(find.text('Confirm location'), findsOneWidget);
    expect(find.byTooltip('Use my location'), findsOneWidget);
  });

  testWidgets('GPS fills the address and Confirm saves coordinates', (
    tester,
  ) async {
    await _openPicker(tester);

    await tester.tap(find.byTooltip('Use my location'));
    await settle(tester);
    expect(find.text('Fort Road, Kannur, Kannur, 670001'), findsOneWidget);

    await tester.tap(find.text('Confirm location'));
    await settle(tester);

    expect(find.text('Your location'), findsNothing);
    final saved = container.read(userLocationProvider);
    expect(saved.latitude, 11.8745);
    expect(saved.longitude, 75.3704);
    expect(saved.addressLine, 'Fort Road, Kannur, Kannur, 670001');
  });

  testWidgets('searching a town selects the match', (tester) async {
    await _openPicker(tester);

    await tester.enterText(find.byType(TextField), 'Palakkad');
    await tester.tap(find.byTooltip('Search a town or city'));
    await settle(tester);
    expect(find.text('Palakkad, Kerala'), findsOneWidget);

    await tester.tap(find.text('Confirm location'));
    await settle(tester);

    final saved = container.read(userLocationProvider);
    expect(saved.label, 'Palakkad, Kerala');
    expect(saved.latitude, 10.7867);
  });

  testWidgets('a town the map cannot find is still saved as typed', (
    tester,
  ) async {
    await _openPicker(tester);

    await tester.enterText(find.byType(TextField), 'Nowhere');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    // The field still holds the query too, so look for the label only.
    expect(
      find.byWidgetPredicate((w) => w is Text && w.data == 'Nowhere'),
      findsOneWidget,
    );

    await tester.tap(find.text('Confirm location'));
    await settle(tester);

    final saved = container.read(userLocationProvider);
    expect(saved.label, 'Nowhere');
    expect(saved.latitude, isNull);
  });

  testWidgets('an empty search asks for a town', (tester) async {
    await _openPicker(tester);

    await tester.tap(find.byTooltip('Search a town or city'));
    await settle(tester, frames: 2);
    expect(find.text('Please enter a town or city'), findsOneWidget);
  });
}
