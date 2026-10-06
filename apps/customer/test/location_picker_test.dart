import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/location_service.dart';
import 'package:kaylo/core/widgets/kaylo_map.dart';
import 'package:kaylo/features/home/application/user_location_provider.dart';
import 'package:kaylo/features/home/presentation/widgets/location_picker_sheet.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'support/test_app.dart';

late ProviderContainer container;
UserLocation? picked;

List<RouteBase> _routes({bool directMap = false}) => [
  GoRoute(
    path: '/',
    builder: (context, _) {
      container = ProviderScope.containerOf(context);
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              if (directMap) {
                picked = await showMapLocationPickerSheet(context);
              } else {
                await showLocationPickerSheet(context);
              }
            },
            child: const Text('open'),
          ),
        ),
      );
    },
  ),
];

Future<void> openPicker(
  WidgetTester tester, {
  bool directMap = false,
  LocationService? service,
}) async {
  useTallPhone(tester);
  picked = null;
  await tester.pumpWidget(
    await testApp(
      initialLocation: '/',
      routes: _routes(directMap: directMap),
      overrides: [
        locationServiceProvider.overrideWithValue(
          service ?? FakeLocationService(),
        ),
      ],
    ),
  );
  await settle(tester);
  await tester.tap(find.text('open'));
  await settle(tester);
}

void main() {
  testWidgets(
    'dashboard chooser lists saved places and selects exact address',
    (tester) async {
      await openPicker(tester);
      expect(find.text('Saved Addresses'), findsOneWidget);
      expect(find.text('Choose on map'), findsOneWidget);
      await tester.tap(find.text('Home'));
      await settle(tester);
      final location = container.read(userLocationProvider);
      expect(location.label, 'Home');
      expect(location.savedAddressId, isNotNull);
      expect(location.fullAddress, isNot('Home'));
      expect(find.text('Your location'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('GPS from chooser saves both exact coordinates and address', (
    tester,
  ) async {
    await openPicker(tester);
    await tester.tap(find.text('Use my location'));
    await settle(tester);
    final saved = container.read(userLocationProvider);
    expect(saved.latitude, 11.8745);
    expect(saved.longitude, 75.3704);
    expect(saved.addressLine, 'Fort Road, Kannur, Kannur, 670001');
  });

  testWidgets('booking map returns searched place without changing dashboard', (
    tester,
  ) async {
    await openPicker(tester, directMap: true);
    await tester.enterText(find.byType(TextField), 'Palakkad');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.text('Palakkad, Kerala'), findsOneWidget);
    await tester.tap(find.text('Confirm location'));
    await settle(tester);
    expect(picked?.latitude, 10.7867);
    expect(picked?.longitude, 76.6548);
    expect(container.read(userLocationProvider).isFallback, isTrue);
  });

  testWidgets('failed map search cannot confirm an unrelated text-only place', (
    tester,
  ) async {
    await openPicker(tester, directMap: true);
    await tester.enterText(find.byType(TextField), 'Nowhere');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    final confirm = tester.widget<KayloButton>(find.byType(KayloButton));
    expect(confirm.onPressed, isNull);
    expect(picked, isNull);
  });

  testWidgets('map drag resolves exact pin without location permission', (
    tester,
  ) async {
    await openPicker(
      tester,
      directMap: true,
      service: FailingLocationService('denied'),
    );
    final map = tester.widget<KayloMap>(find.byType(KayloMap));
    map.onCameraIdle!(); // Map-ready callback, as on real engines.
    await settle(tester);
    map.onCameraMoveStarted!();
    map.onCameraMove!(const LatLng(11.12, 75.31));
    map.onCameraIdle!();
    await settle(tester);
    await tester.tap(find.text('Confirm location'));
    await settle(tester);
    expect(picked?.latitude, 11.12);
    expect(picked?.longitude, 75.31);
    expect(picked?.bookingNotes, contains('query=11.12,75.31'));
  });

  testWidgets(
    'moving pin disables confirm and ignores a stale address lookup',
    (tester) async {
      final service = DelayedLocationService();
      await openPicker(tester, directMap: true, service: service);
      final map = tester.widget<KayloMap>(find.byType(KayloMap));
      map.onCameraIdle!();
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.requests.length, 1);
      map.onCameraMoveStarted!();
      map.onCameraMove!(const LatLng(12, 76));
      service.requests.first.complete(
        const ResolvedLocation(latitude: 11, longitude: 75, label: 'Old pin'),
      );
      await tester.pump();
      expect(find.text('Old pin'), findsNothing);
      final confirm = tester.widget<KayloButton>(find.byType(KayloButton));
      expect(confirm.onPressed, isNull);
      map.onCameraIdle!();
      await tester.pump(const Duration(milliseconds: 500));
      service.requests.last.complete(
        const ResolvedLocation(latitude: 12, longitude: 76, label: 'New pin'),
      );
      await settle(tester);
      await tester.tap(find.text('Confirm location'));
      await settle(tester);
      expect(picked?.label, 'New pin');
    },
  );
}

class DelayedLocationService extends FakeLocationService {
  final requests = <Completer<ResolvedLocation>>[];
  @override
  Future<ResolvedLocation> resolve(double latitude, double longitude) {
    final request = Completer<ResolvedLocation>();
    requests.add(request);
    return request.future;
  }
}
