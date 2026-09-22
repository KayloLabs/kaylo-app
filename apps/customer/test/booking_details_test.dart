import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/booking/presentation/screens/booking_details_screen.dart';
import 'package:kaylo/features/booking/presentation/screens/bookings_screen.dart';

import 'support/test_app.dart';

final _routes = <RouteBase>[
  GoRoute(
    path: Routes.bookings,
    builder: (_, _) => const BookingsScreen(),
    routes: [
      GoRoute(
        path: ':bookingId',
        builder: (_, state) =>
            BookingDetailsScreen(bookingId: state.pathParameters['bookingId']!),
      ),
    ],
  ),
  stubRoute('/chat/:threadId', 'chat-stub'),
];

void main() {
  testWidgets('a booking card opens its details with the worker', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(initialLocation: Routes.bookings, routes: _routes),
    );
    await settle(tester);

    await tester.tap(find.text('Plumbing'));
    await settle(tester);

    expect(find.text('Booking details'), findsOneWidget);
    expect(find.text('Manoj P.'), findsOneWidget);
    expect(find.text('Reschedule'), findsOneWidget);
    expect(find.text('Cancel booking'), findsOneWidget);
  });

  testWidgets('rescheduling updates the booking', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: Routes.bookingDetails('b3'),
        routes: _routes,
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Reschedule'));
    await settle(tester);
    await tester.tap(find.text('4:30 PM - 6:30 PM'));
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('Booking rescheduled'), findsOneWidget);
    expect(find.text('4:30 PM'), findsOneWidget);
  });

  testWidgets('cancelling asks first, then marks the booking cancelled', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: Routes.bookingDetails('b3'),
        routes: _routes,
      ),
    );
    await settle(tester);

    await tester.tap(find.text('Cancel booking'));
    await settle(tester);
    expect(find.text('Cancel this booking?'), findsOneWidget);

    await tester.tap(find.text('Keep booking'));
    await settle(tester);
    expect(find.text('Cancelled'), findsNothing);

    await tester.tap(find.text('Cancel booking'));
    await settle(tester);
    await tester.tap(find.text('Cancel booking').last);
    await settle(tester);

    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('This booking was cancelled.'), findsOneWidget);
    expect(find.text('Reschedule'), findsNothing);
  });

  testWidgets('a completed booking has no actions', (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: Routes.bookingDetails('b1'),
        routes: _routes,
      ),
    );
    await settle(tester);

    expect(find.text('Completed'), findsWidgets);
    expect(find.text('Reschedule'), findsNothing);
    expect(find.text('Cancel booking'), findsNothing);
  });
}
