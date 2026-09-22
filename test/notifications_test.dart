import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/notifications/application/notifications_providers.dart';
import 'package:kaylo/features/notifications/presentation/screens/notifications_screen.dart';

import 'support/test_app.dart';

void main() {
  testWidgets('notifications list, unread count, and mark all read',
      (tester) async {
    useTallPhone(tester);
    late ProviderContainer container;
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.notifications,
      routes: [
        GoRoute(
          path: Routes.notifications,
          builder: (context, _) {
            container = ProviderScope.containerOf(context);
            return const NotificationsScreen();
          },
        ),
        stubRoute(Routes.bookings, 'bookings-stub'),
      ],
    ));
    await settle(tester);

    expect(find.text('Booking confirmed'), findsOneWidget);
    // "Today" depends on the wall clock (a 20-minute-old item is
    // yesterday's just after midnight); the 3-day-old one is always earlier.
    expect(find.text('Earlier'), findsOneWidget);
    expect(container.read(unreadNotificationsCountProvider), 3);

    await tester.tap(find.text('Mark all read'));
    await settle(tester);

    expect(container.read(unreadNotificationsCountProvider), 0);
    expect(find.text('Mark all read'), findsNothing);
  });

  testWidgets('tapping a booking notification opens the bookings tab',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(await testApp(
      initialLocation: Routes.notifications,
      routes: [
        GoRoute(
          path: Routes.notifications,
          builder: (_, _) => const NotificationsScreen(),
        ),
        stubRoute(Routes.bookings, 'bookings-stub'),
      ],
    ));
    await settle(tester);

    await tester.tap(find.text('Booking confirmed'));
    await settle(tester);

    expect(find.text('bookings-stub'), findsOneWidget);
  });
}
