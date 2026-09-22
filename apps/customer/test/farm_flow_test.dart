import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/booking/domain/booking_receipt.dart';
import 'package:kaylo/features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_payment_screen.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_schedule_screen.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_service_details_screen.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_services_screen.dart';

import 'support/test_app.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: Routes.farm,
    builder: (_, _) => const FarmServicesScreen(),
    routes: [
      GoRoute(
        path: ':serviceId',
        builder: (_, state) => FarmServiceDetailsScreen(
          serviceId: state.pathParameters['serviceId']!,
        ),
        routes: [
          GoRoute(
            path: 'schedule',
            builder: (_, state) => FarmScheduleScreen(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: 'payment',
            builder: (_, state) =>
                FarmPaymentScreen(draft: state.extra as FarmBookingDraft?),
          ),
        ],
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
  testWidgets('catalog lists farm services and opens details', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.farm, routes: _routes),
    );
    await settle(tester);

    expect(find.text('Coconut Plucking'), findsOneWidget);
    expect(find.text('Tree Pruning'), findsOneWidget);
    expect(
      find.text('Plumbing'),
      findsNothing,
      reason: 'home services stay out',
    );

    await tester.tap(find.text('Coconut Plucking'));
    await settle(tester);

    expect(find.text('Book now'), findsOneWidget);
    expect(find.text('What the worker commits to'), findsOneWidget);
    expect(find.text('Safety harness on every climb'), findsOneWidget);
  });

  testWidgets('schedule recomputes the total from the quantity', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.farmSchedule('1'), routes: _routes),
    );
    await settle(tester);

    // 10 trees x 1000 to start with.
    expect(find.text('₹10,000'), findsWidgets);
    expect(find.text('₹1,000 × 10 trees'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();

    expect(find.text('₹11,000'), findsWidgets);
    expect(find.text('₹1,000 × 11 trees'), findsOneWidget);
  });

  testWidgets('address is required before payment', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.farmSchedule('1'), routes: _routes),
    );
    await settle(tester);

    await tester.tap(find.text('Continue to payment'));
    await tester.pump();

    expect(find.text('Please enter the farm address'), findsOneWidget);
    expect(find.text('Order summary'), findsNothing);
  });

  testWidgets('a saved address fills the field in one tap', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.farmSchedule('1'), routes: _routes),
    );
    await settle(tester);

    expect(find.text('Use my location'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pump();

    final field = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(field.controller!.text, isNotEmpty);
  });

  testWidgets('payment records the booking and confirms it', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.farmSchedule('1'), routes: _routes),
    );
    await settle(tester);

    await tester.enterText(find.byType(TextFormField), 'Thekkedath House');
    await tester.tap(find.text('Continue to payment'));
    await settle(tester);

    expect(find.text('Order summary'), findsOneWidget);
    expect(find.text('Thekkedath House'), findsOneWidget);

    await tester.tap(find.text('Confirm and pay ₹10,000'));
    await settle(tester);

    expect(find.text('Booking confirmed'), findsOneWidget);
    expect(find.text('10 trees'), findsOneWidget);
    expect(find.text('Confirmed'), findsOneWidget);

    await tester.tap(find.text('View my bookings'));
    await settle(tester);
    expect(find.text('bookings-stub'), findsOneWidget);
  });
}
