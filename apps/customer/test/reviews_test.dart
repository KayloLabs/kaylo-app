import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/features/reviews/application/reviews_providers.dart';
import 'package:kaylo/features/reviews/data/mock_reviews_repository.dart';
import 'package:kaylo/features/reviews/presentation/widgets/rate_worker_card.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_app.dart';

final completed = Booking(
  id: 'KL-done-1',
  userId: 'mock_uid_1',
  serviceId: 'plumbing',
  workerId: 'w1',
  scheduledAt: DateTime(2026, 10, 1, 9),
  status: BookingStatus.completed,
  totalAmount: 300,
  paymentMode: PaymentMode.cash,
);

void main() {
  test('a review is kept on the device and can be rewritten', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockReviewsRepository(prefs);
    expect(await repo.getForBooking('KL-done-1'), isNull);
    final first = await repo.submit(
      bookingId: 'KL-done-1',
      workerId: 'w1',
      rating: 4,
      text: '  Neat work  ',
    );
    expect(first.text, 'Neat work');
    final again = await repo.submit(
      bookingId: 'KL-done-1',
      workerId: 'w1',
      rating: 5,
      text: '',
    );
    expect(again.rating, 5);
    expect(again.text, isNull);
    // A fresh repository over the same preferences still has it.
    final reloaded = await MockReviewsRepository(
      prefs,
    ).getForBooking('KL-done-1');
    expect(reloaded?.rating, 5);
    expect(
      () => repo.submit(bookingId: 'x', workerId: 'w1', rating: 0),
      throwsArgumentError,
    );
  });

  testWidgets(
    'a completed booking can be rated from the details card',
    (tester) async {
      useTallPhone(tester);
      final handle = tester.ensureSemantics();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        await testApp(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Scaffold(
                body: ListView(children: [RateWorkerCard(booking: completed)]),
              ),
            ),
          ],
          overrides: [
            reviewsRepositoryProvider.overrideWithValue(
              MockReviewsRepository(prefs),
            ),
          ],
        ),
      );
      await settle(tester);
      expect(find.text('Rate your worker'), findsWidgets);

      await tester.tap(find.widgetWithText(KayloButton, 'Rate your worker'));
      await settle(tester);
      // Submitting without stars is refused.
      await tester.tap(find.text('Submit review'));
      await settle(tester);
      expect(find.text('Pick a star rating first'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('4 of 5 stars'));
      await tester.enterText(find.byType(TextField), 'Came on time');
      await tester.tap(find.text('Submit review'));
      await settle(tester);

      expect(find.text('Thanks, your review is in'), findsOneWidget);
      expect(find.text('Your review'), findsOneWidget);
      expect(find.text('Came on time'), findsOneWidget);
      // Persisted, not only shown: the device copy carries the 4 stars.
      expect(prefs.getString('kaylo_booking_reviews'), contains('"rating":4'));
      handle.dispose();
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
