import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/booking/application/bookings_providers.dart';
import 'package:kaylo/features/booking/data/mock_bookings_repository.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/farm/presentation/screens/farm_schedule_screen.dart';
import 'package:kaylo_core/models/booking.dart';

import 'support/test_app.dart';

DateTime _tomorrowAt(int hour) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + 1, hour);
}

void main() {
  test('a slot is taken when a held time falls inside it', () {
    final eight = FarmTimeSlot.all[1]; // 08:00 to 10:00
    expect(eight.isTakenBy({8 * 60}), isTrue);
    expect(eight.isTakenBy({9 * 60 + 30}), isTrue);
    expect(eight.isTakenBy({10 * 60}), isFalse);
    expect(FarmTimeSlot.firstFree({7 * 60, 8 * 60}), FarmTimeSlot.all[2]);
    expect(
      FarmTimeSlot.firstFree({
        for (final s in FarmTimeSlot.all) s.startMinutes,
      }),
      isNull,
    );
  });

  test(
    'the sample repository reports a worker\'s held times for a day',
    () async {
      final repo = MockBookingsRepository();
      final day = _tomorrowAt(0);
      expect(await repo.takenSlotMinutes('w1', day), isEmpty);
      final booking = await repo.createBooking(
        Booking(
          id: '',
          userId: 'mock_uid_1',
          serviceId: '4',
          workerId: 'w1',
          scheduledAt: _tomorrowAt(8),
          status: BookingStatus.pending,
          totalAmount: 300,
        ),
      );
      expect(await repo.takenSlotMinutes('w1', day), {8 * 60});
      expect(await repo.takenSlotMinutes('w2', day), isEmpty);
      await repo.updateBookingStatus(booking.id, BookingStatus.cancelled);
      expect(await repo.takenSlotMinutes('w1', day), isEmpty);
    },
  );

  testWidgets('a held slot shows as booked and cannot be picked', (
    tester,
  ) async {
    useTallPhone(tester);
    final repo = MockBookingsRepository();
    // The sample repository answers after a short delay; under fake time
    // that needs a real-async window or the test never gets its booking.
    await tester.runAsync(
      () => repo.createBooking(
        Booking(
          id: '',
          userId: 'someone_else',
          serviceId: '4',
          workerId: 'w1',
          scheduledAt: _tomorrowAt(8),
          status: BookingStatus.confirmed,
          totalAmount: 300,
        ),
      ),
    );
    await tester.pumpWidget(
      await testApp(
        initialLocation: '${Routes.bookService}?serviceId=4&workerId=w1',
        routes: [
          GoRoute(
            path: Routes.bookService,
            builder: (_, state) => FarmScheduleScreen(
              serviceId: state.uri.queryParameters['serviceId'] ?? '',
              workerId: state.uri.queryParameters['workerId'],
            ),
          ),
        ],
        overrides: [bookingsRepositoryProvider.overrideWithValue(repo)],
      ),
    );
    await settle(tester);

    // 08:00 sits inside both the 07:00-09:00 and 08:00-10:00 windows, so
    // both show as booked: the worker is busy for either.
    final booked = find.textContaining('Booked');
    expect(booked, findsNWidgets(2));
    for (final element in booked.evaluate()) {
      final chip = tester.widget<ChoiceChip>(
        find.ancestor(
          of: find.byWidget(element.widget),
          matching: find.byType(ChoiceChip),
        ),
      );
      expect(chip.onSelected, isNull, reason: 'a held slot is not selectable');
      expect(chip.selected, isFalse, reason: 'selection moved off held slots');
    }
    // Another slot is selected instead.
    final selected = tester
        .widgetList<ChoiceChip>(find.byType(ChoiceChip))
        .where((c) => c.selected);
    expect(selected.length, 1);
  });
}
