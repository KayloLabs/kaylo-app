import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/features/offers/application/offers_providers.dart';
import 'package:kaylo/features/offers/domain/kaylo_offer.dart';
import 'package:kaylo/features/offers/presentation/offers_screen.dart';
import 'package:kaylo_core/models/booking.dart';
import 'support/test_app.dart';

Booking booking({
  BookingStatus status = BookingStatus.completed,
  String? offer,
}) => Booking(
  id: 'one',
  userId: 'user',
  serviceId: 'service',
  scheduledAt: DateTime(2026, 10, 2),
  status: status,
  totalAmount: 500,
  offerCode: offer,
);

void main() {
  final saturday = DateTime(2026, 10, 3);
  test(
    'first booking minimum is exact, and existing booking removes eligibility',
    () {
      final welcome = demoOffers([], saturday).first;
      expect(welcome.savings(498.99), 0);
      expect(welcome.savings(499), 100);
      expect(demoOffers([booking()], saturday).first.eligible, isFalse);
      expect(
        demoOffers([
          booking(status: BookingStatus.cancelled),
        ], saturday).first.eligible,
        isTrue,
      );
    },
  );
  test(
    'scratch reward unlocks only after confirmation and can be used once',
    () {
      KayloOffer reward(List<Booking> history) =>
          demoOffers(history, saturday).last;
      expect(reward([]).eligible, isFalse);
      expect(
        reward([booking(status: BookingStatus.pending)]).eligible,
        isFalse,
      );
      expect(
        reward([booking(status: BookingStatus.confirmed)]).savings(799),
        75,
      );
      expect(reward([booking(offer: 'NEXT75')]).eligible, isFalse);
    },
  );
  test('weekend rules and one-per-account eligibility are distinct', () {
    expect(demoOffers([], DateTime(2026, 10, 5))[2].eligible, isFalse);
    expect(demoOffers([], saturday)[2].savings(999), 100);
    expect(
      demoOffers([booking(offer: 'WEEKEND100')], saturday)[2].eligible,
      isFalse,
    );
    expect(demoOffers([booking()], saturday)[1].savings(1499), 150);
  });
  testWidgets(
    'coupon code is validated and eligible offer is returned to checkout',
    (tester) async {
      useTallPhone(tester);
      KayloOffer? selected;
      await tester.pumpWidget(
        await testApp(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () async {
                    selected = await showKayloOffers(context, subtotal: 500);
                  },
                  child: const Text('Choose offer'),
                ),
              ),
            ),
          ],
          overrides: [
            offersProvider.overrideWith(
              (ref) async => demoOffers([], saturday),
            ),
          ],
        ),
      );
      await tester.tap(find.text('Choose offer'));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.tap(find.widgetWithText(TextButton, 'Apply').first);
      await tester.pump();
      expect(find.text('That code isn’t available'), findsOneWidget);
      await tester.enterText(find.byType(TextField), ' first100 ');
      await tester.tap(find.widgetWithText(TextButton, 'Apply').first);
      await settle(tester);
      expect(selected?.code, 'FIRST100');
      expect(selected?.savings(500), 100);
    },
  );
  testWidgets('scratch has an accessible reveal', (tester) async {
    useTallPhone(tester);
    final reward = demoOffers([booking()], saturday).last;
    await tester.pumpWidget(
      await testApp(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: ScratchReward(
                offer: reward,
                userId: testUser.id,
                subtotal: 800,
                onApply: () {},
              ),
            ),
          ),
        ],
      ),
    );
    expect(find.text('Reveal reward'), findsOneWidget);
    await tester.tap(find.text('Reveal reward'));
    await settle(tester);
    expect(find.text('Reveal reward'), findsNothing);
    expect(find.text('NEXT75'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('offers remain usable on a narrow phone with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(640, 1440);
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      await testApp(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const OffersScreen(subtotal: 1600),
          ),
        ],
        overrides: [
          offersProvider.overrideWith((ref) async => demoOffers([], saturday)),
        ],
      ),
    );
    await settle(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await settle(tester);
    expect(tester.takeException(), isNull);
  });
}
