import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/location_service.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_schedule_screen.dart';
import 'support/test_app.dart';
import 'package:kaylo/features/home/presentation/widgets/location_picker_sheet.dart';
import 'package:kaylo/features/profile/application/addresses_providers.dart';
import 'package:kaylo/features/profile/domain/saved_address.dart';

void main() {
  testWidgets('booking sends chosen map pin and address to checkout', (
    tester,
  ) async {
    useTallPhone(tester);
    FarmBookingDraft? checkout;
    await tester.pumpWidget(
      await testApp(
        initialLocation: '/schedule',
        overrides: [
          locationServiceProvider.overrideWithValue(FakeLocationService()),
        ],
        routes: [
          GoRoute(
            path: '/schedule',
            builder: (_, _) => const FarmScheduleScreen(serviceId: '1'),
          ),
          GoRoute(
            path: Routes.farmPayment('1'),
            builder: (_, state) {
              checkout = state.extra as FarmBookingDraft;
              return const Scaffold(body: Text('checkout'));
            },
          ),
        ],
      ),
    );
    await settle(tester);
    await tester.tap(find.text('Choose on map'));
    await settle(tester);
    await tester.enterText(
      find.descendant(
        of: find.byType(LocationPickerSheet),
        matching: find.byType(TextField),
      ),
      'Palakkad',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    await tester.tap(find.text('Confirm location'));
    await settle(tester);
    await tester.tap(find.text('Continue to payment'));
    await settle(tester);
    expect(checkout?.address, 'Palakkad, Kerala');
    expect(checkout?.latitude, 10.7867);
    expect(checkout?.longitude, 76.6548);
    expect(checkout?.bookingNotes, contains('query=10.7867,76.6548'));
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'saved booking address carries its database id and exact coordinates',
    (tester) async {
      useTallPhone(tester);
      FarmBookingDraft? checkout;
      await tester.pumpWidget(
        await testApp(
          initialLocation: '/schedule',
          overrides: [
            savedAddressesProvider.overrideWith(
              (_) async => [
                const SavedAddress(
                  id: 'address-42',
                  label: 'West farm',
                  line: 'Old mill road',
                  latitude: 11.52,
                  longitude: 75.72,
                ),
              ],
            ),
          ],
          routes: [
            GoRoute(
              path: '/schedule',
              builder: (_, _) => const FarmScheduleScreen(serviceId: '1'),
            ),
            GoRoute(
              path: Routes.farmPayment('1'),
              builder: (_, state) {
                checkout = state.extra as FarmBookingDraft;
                return const Scaffold(body: Text('checkout'));
              },
            ),
          ],
        ),
      );
      await settle(tester);
      await tester.tap(find.text('West farm'));
      await tester.pump();
      await tester.tap(find.text('Continue to payment'));
      await settle(tester);
      expect(checkout?.address, 'Old mill road');
      expect(checkout?.locationId, 'address-42');
      expect(checkout?.latitude, 11.52);
      expect(checkout?.longitude, 75.72);
      expect(checkout?.bookingNotes, contains('query=11.52,75.72'));
    },
  );
}
