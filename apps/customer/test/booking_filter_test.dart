import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/features/booking/application/bookings_providers.dart';
import 'package:kaylo/features/booking/presentation/screens/bookings_screen.dart';
import 'package:kaylo_core/models/booking.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('Completed filter never includes cancelled or expired jobs', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: '/bookings?status=completed',
        routes: [
          GoRoute(
            path: '/bookings',
            builder: (_, state) => BookingsScreen(
              completedOnly: state.uri.queryParameters['status'] == 'completed',
            ),
          ),
        ],
        overrides: [
          userBookingsProvider.overrideWith(
            (ref) => Stream.value([
              for (final status in BookingStatus.values)
                Booking(
                  id: 'booking-${status.name}',
                  userId: testUser.id,
                  serviceId: '4',
                  scheduledAt: DateTime(2020),
                  status: status,
                  totalAmount: 100,
                ),
            ]),
          ),
        ],
      ),
    );
    await settle(tester);
    expect(find.text('booking-completed'), findsOneWidget);
    for (final status in BookingStatus.values) {
      if (status != BookingStatus.completed) {
        expect(find.text('booking-${status.name}'), findsNothing);
      }
    }
  });

  testWidgets('Completed has its own empty state and return to all', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: '/bookings?status=completed',
        routes: [
          GoRoute(
            path: '/bookings',
            builder: (_, state) => BookingsScreen(
              completedOnly: state.uri.queryParameters['status'] == 'completed',
            ),
          ),
        ],
        overrides: [
          userBookingsProvider.overrideWith((ref) => Stream.value([])),
        ],
      ),
    );
    await settle(tester);
    expect(find.text('No completed bookings yet'), findsOneWidget);
    await tester.tap(find.text('All bookings').first);
    await settle(tester);
    expect(find.text('No completed bookings yet'), findsNothing);
  });
}
