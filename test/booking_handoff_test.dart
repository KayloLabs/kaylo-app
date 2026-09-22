import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/booking/application/bookings_providers.dart';
import 'package:kaylo/features/booking/data/mock_bookings_repository.dart';
import 'package:kaylo/features/booking/domain/booking_receipt.dart';
import 'package:kaylo/features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_payment_screen.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_schedule_screen.dart';

import 'support/test_app.dart';

/// The home flow (details -> workers -> profile) hands off to the same
/// schedule and payment steps the farm flow uses, via
/// `/book-service?serviceId=&workerId=`. These tests cover that handoff
/// with the router wiring from app_router.dart.
final _routes = <RouteBase>[
  GoRoute(
    path: Routes.bookService,
    builder: (_, state) {
      final workerId = state.uri.queryParameters['workerId'];
      return FarmScheduleScreen(
        serviceId: state.uri.queryParameters['serviceId'] ?? '',
        workerId: workerId == null || workerId.isEmpty ? null : workerId,
      );
    },
  ),
  GoRoute(
    path: '/farm/:serviceId/payment',
    builder: (_, state) => FarmPaymentScreen(
      draft: state.extra as FarmBookingDraft?,
    ),
  ),
  GoRoute(
    path: Routes.bookingConfirmation,
    builder: (_, state) => BookingConfirmationScreen(
      receipt: state.extra as BookingReceipt?,
    ),
  ),
  stubRoute(Routes.bookings, 'bookings-stub'),
  stubRoute(Routes.dashboard, 'dashboard-stub'),
];

Future<Widget> _app(String location, MockBookingsRepository bookings) =>
    testApp(
      initialLocation: location,
      routes: _routes,
      overrides: [bookingsRepositoryProvider.overrideWithValue(bookings)],
    );

void main() {
  testWidgets('book-service opens the schedule for a home service',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await _app(
      '${Routes.bookService}?serviceId=4&workerId=w1',
      MockBookingsRepository(),
    ));
    await settle(tester);

    expect(find.text('Plumbing'), findsOneWidget);
    expect(find.text('1 visit'), findsOneWidget, reason: 'a callout is one visit');
    expect(find.text('Service address'), findsOneWidget);
    expect(find.text('Farm address'), findsNothing);
    expect(find.textContaining('Handoff to M4'), findsNothing);
  });

  testWidgets('a home booking keeps the chosen worker through to the record',
      (tester) async {
    useTallPhone(tester);
    final bookings = MockBookingsRepository();
    // The mock answers after a real delay, so read it outside fake time.
    final before = (await tester.runAsync(
      () => bookings.getUserBookings('mock_uid_1'),
    ))!
        .length;

    await tester.pumpWidget(await _app(
      '${Routes.bookService}?serviceId=4&workerId=w1',
      bookings,
    ));
    await settle(tester);

    await tester.tap(find.text('Continue to payment'));
    await tester.pump();
    expect(find.text('Please enter the service address'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'Kadavil House, Kannur');
    await tester.tap(find.text('Continue to payment'));
    await settle(tester);

    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);
    expect(find.text('Raju K.'), findsOneWidget);
    expect(find.text('Service address'), findsOneWidget);

    await tester.tap(find.text('Confirm and pay ₹500'));
    await settle(tester);

    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('Raju K.'), findsOneWidget);

    final after = (await tester.runAsync(
      () => bookings.getUserBookings('mock_uid_1'),
    ))!;
    expect(after.length, before + 1);
    expect(after.last.serviceId, '4');
    expect(after.last.workerId, 'w1');
  });

  testWidgets('book-service without a worker leaves the assignment open',
      (tester) async {
    useTallPhone(tester);
    final bookings = MockBookingsRepository();
    await tester.pumpWidget(await _app(
      '${Routes.bookService}?serviceId=4',
      bookings,
    ));
    await settle(tester);

    await tester.enterText(find.byType(TextFormField), 'Kadavil House');
    await tester.tap(find.text('Continue to payment'));
    await settle(tester);

    expect(find.text('Worker'), findsNothing);

    await tester.tap(find.text('Confirm and pay ₹500'));
    await settle(tester);

    final created = (await tester.runAsync(
      () => bookings.getUserBookings('mock_uid_1'),
    ))!
        .last;
    expect(created.serviceId, '4');
    expect(created.workerId, isNull);
  });
}
