import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/core/services/location_service.dart';
import 'package:kaylo/features/booking/domain/booking_draft.dart';
import 'package:kaylo/features/booking/domain/booking_receipt.dart';
import 'package:kaylo/features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:kaylo/features/booking/presentation/screens/payment_screen.dart';
import 'package:kaylo/features/booking/presentation/screens/schedule_screen.dart';
import 'package:kaylo/features/profile/application/addresses_providers.dart';
import 'package:kaylo/features/services/presentation/screens/service_details_screen.dart';
import 'package:kaylo/features/services/presentation/screens/services_list_screen.dart';

import 'support/test_app.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: '/services/:category',
    builder: (_, state) =>
        ServicesListScreen(category: state.pathParameters['category']!),
  ),
  GoRoute(
    path: '/service/:serviceId',
    builder: (_, state) =>
        ServiceDetailsScreen(serviceId: state.pathParameters['serviceId']!),
    routes: [
      GoRoute(
        path: 'schedule',
        builder: (_, state) =>
            ScheduleScreen(serviceId: state.pathParameters['serviceId']!),
      ),
      GoRoute(
        path: 'payment',
        builder: (_, state) =>
            PaymentScreen(draft: state.extra as BookingDraft?),
      ),
    ],
  ),
  GoRoute(
    path: Routes.bookingConfirmation,
    builder: (_, state) =>
        BookingConfirmationScreen(receipt: state.extra as BookingReceipt?),
  ),
  stubRoute(Routes.bookings, 'bookings-stub'),
  stubRoute(Routes.dashboard, 'dashboard-stub'),
];

void main() {
  testWidgets('farm catalog lists farm services and opens details',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.services('farm'),
      routes: _routes,
    ));
    await settle(tester);

    expect(find.text('Coconut Plucking'), findsOneWidget);
    expect(find.text('Tree Pruning'), findsOneWidget);
    expect(find.text('Plumbing'), findsNothing, reason: 'home services stay out');

    await tester.tap(find.text('Coconut Plucking'));
    await settle(tester);

    expect(find.text('Book now'), findsOneWidget);
    expect(find.text('Safety harness on every climb'), findsOneWidget);
  });

  testWidgets('home catalog lists home services with per-visit pricing',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.services('home'),
      routes: _routes,
    ));
    await settle(tester);

    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.textContaining('per visit', findRichText: true), findsWidgets);
    expect(find.text('Coconut Plucking'), findsNothing);
  });

  testWidgets('schedule prefills the default address and recomputes the total',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.serviceSchedule('1'),
      routes: _routes,
    ));
    await settle(tester);

    // Seeded default address lands in the field; 10 trees x 1000.
    expect(find.text('Thekkedath House, Kaloor, Kannur 670001'), findsOneWidget);
    expect(find.text('₹10,000'), findsWidgets);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('₹11,000'), findsWidgets);
    expect(find.text('₹1,000 × 11 trees'), findsOneWidget);
  });

  testWidgets('use my location fills the address from GPS', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.serviceSchedule('4'),
      routes: _routes,
      overrides: [
        savedAddressesProvider.overrideWith((ref) async => const []),
        locationServiceProvider.overrideWithValue(FakeLocationService()),
      ],
    ));
    await settle(tester);

    await tester.tap(find.text('Use my location'));
    await settle(tester);

    expect(find.text('Fort Road, Kannur, Kannur, 670001'), findsOneWidget);
  });

  testWidgets('a denied GPS permission is explained, not swallowed',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.serviceSchedule('4'),
      routes: _routes,
      overrides: [
        savedAddressesProvider.overrideWith((ref) async => const []),
        locationServiceProvider
            .overrideWithValue(FailingLocationService('denied')),
      ],
    ));
    await settle(tester);

    await tester.tap(find.text('Use my location'));
    await settle(tester);

    expect(find.text('Location permission was not granted.'), findsOneWidget);
  });

  testWidgets('address is required before payment', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.serviceSchedule('1'),
      routes: _routes,
      overrides: [savedAddressesProvider.overrideWith((ref) async => const [])],
    ));
    await settle(tester);

    await tester.tap(find.text('Continue to payment'));
    await tester.pump();

    expect(find.text('Please enter the farm address'), findsOneWidget);
    expect(find.text('Order summary'), findsNothing);
  });

  testWidgets('payment records the booking and confirms it', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.serviceSchedule('1'),
      routes: _routes,
    ));
    await settle(tester);

    await tester.tap(find.text('Continue to payment'));
    await settle(tester);

    expect(find.text('Order summary'), findsOneWidget);
    await tester.tap(find.text('Confirm and pay ₹10,000'));
    await settle(tester);

    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('10 trees'), findsOneWidget);

    await tester.tap(find.text('View my bookings'));
    await settle(tester);
    expect(find.text('bookings-stub'), findsOneWidget);
  });
}
