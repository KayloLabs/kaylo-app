import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/booking/application/bookings_providers.dart';
import 'package:kaylo/features/booking/data/mock_bookings_repository.dart';
import 'package:kaylo/features/booking/domain/booking_receipt.dart';
import 'package:kaylo/features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_payment_screen.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_schedule_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';

/// The home flow (details -> workers -> profile) hands off to the same
/// schedule and payment steps the farm flow uses, via
/// `/book-service?serviceId=&workerId=`. These tests cover that handoff
/// with the router wiring from app_router.dart.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void useTallPhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
}

Widget app({
  required String initialLocation,
  required MockBookingsRepository bookings,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
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
      GoRoute(
        path: Routes.bookings,
        builder: (_, _) => const Scaffold(body: Text('bookings-stub')),
      ),
      GoRoute(
        path: Routes.dashboard,
        builder: (_, _) => const Scaffold(body: Text('dashboard-stub')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('mock_uid_1'),
      bookingsRepositoryProvider.overrideWithValue(bookings),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('book-service opens the schedule for a home service',
      (tester) async {
    useTallPhone(tester);
    await tester.pumpWidget(app(
      initialLocation: '${Routes.bookService}?serviceId=4&workerId=w1',
      bookings: MockBookingsRepository(),
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

    await tester.pumpWidget(app(
      initialLocation: '${Routes.bookService}?serviceId=4&workerId=w1',
      bookings: bookings,
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
    await tester.pumpWidget(app(
      initialLocation: '${Routes.bookService}?serviceId=4',
      bookings: bookings,
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
