import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/features/offers/application/offers_providers.dart';
import 'package:kaylo/features/offers/domain/kaylo_offer.dart';
import 'package:kaylo/features/offers/presentation/offer_ticket.dart';
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

/// The offers are a list in display order; tests ask for one by its code.
KayloOffer offer(String code, List<Booking> history, DateTime now) =>
    demoOffers(history, now).singleWhere((o) => o.code == code);

void main() {
  final saturday = DateTime(2026, 10, 3);
  final monday = DateTime(2026, 10, 5);
  test(
    'first booking minimum is exact, and existing booking removes eligibility',
    () {
      final welcome = offer('FIRST100', [], saturday);
      expect(welcome.savings(498.99), 0);
      expect(welcome.savings(499), 100);
      expect(offer('FIRST100', [booking()], saturday).eligible, isFalse);
      expect(
        offer('FIRST100', [
          booking(status: BookingStatus.cancelled),
        ], saturday).eligible,
        isTrue,
      );
    },
  );
  test(
    'scratch reward unlocks only after confirmation and can be used once',
    () {
      KayloOffer reward(List<Booking> history) =>
          offer('NEXT75', history, saturday);
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
    expect(offer('WEEKEND100', [], monday).eligible, isFalse);
    expect(offer('WEEKEND100', [], saturday).savings(999), 100);
    expect(
      offer('WEEKEND100', [booking(offer: 'WEEKEND100')], saturday).eligible,
      isFalse,
    );
    expect(offer('KAYLO150', [booking()], saturday).savings(1499), 150);
    // The working week has its own offer, closed while the weekend one is open.
    expect(offer('WEEKDAY50', [], monday).savings(599), 50);
    expect(offer('WEEKDAY50', [], saturday).reasonCode, 'weekday_only');
  });
  test('an offer for one kind of service only fits that kind', () {
    final farm = offer('FARM125', [], saturday);
    expect(farm.savings(1200, category: 'farm'), 125);
    expect(farm.blockFor(1200, category: 'home'), OfferBlock.wrongCategory);
    expect(farm.blockFor(900, category: 'farm'), OfferBlock.belowMinimum);
    // While only browsing there is no booking yet, so the kind is not held
    // against the offer.
    expect(farm.appliesTo(1200), isTrue);
    expect(
      offer('FARM125', [booking(offer: 'FARM125')], saturday).eligible,
      isFalse,
    );
    expect(offer('CARE60', [], saturday).savings(500, category: 'care'), 60);
    expect(offer('HOME80', [], saturday).savings(499, category: 'home'), 80);
    expect(offer('HOME80', [], saturday).savings(498, category: 'home'), 0);
  });
  test('the second scratch reward waits for three confirmed bookings', () {
    Booking done(String id) => Booking(
      id: id,
      userId: 'user',
      serviceId: 'service',
      scheduledAt: DateTime(2026, 10, 2),
      status: BookingStatus.completed,
      totalAmount: 500,
    );
    final two = offer('THANKS120', [done('a'), done('b')], saturday);
    expect(two.eligible, isFalse);
    expect(two.reasonCode, 'needs_three');
    final three = offer('THANKS120', [
      done('a'),
      done('b'),
      done('c'),
    ], saturday);
    expect(three.scratch, isTrue);
    expect(three.savings(999), 120);
    expect(demoOffers([], saturday).map((o) => o.code).toSet(), hasLength(10));
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
    final reward = offer('NEXT75', [booking()], saturday);
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
  testWidgets('scratching about half the foil opens the reward', (
    tester,
  ) async {
    useTallPhone(tester);
    final reward = offer('NEXT75', [booking()], saturday);
    await tester.pumpWidget(
      await testApp(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(24),
                child: ScratchReward(
                  offer: reward,
                  userId: testUser.id,
                  subtotal: 800,
                  onApply: () {},
                ),
              ),
            ),
          ),
        ],
      ),
    );
    // The coin makes its one short scratch; that alone opens nothing.
    await settle(tester);
    expect(find.text('Reveal reward'), findsOneWidget);
    final card = tester.getRect(find.byType(OfferTicket));
    for (final row in [.14, .38, .62, .86]) {
      await tester.timedDragFrom(
        Offset(card.left + 24, card.top + card.height * row),
        Offset(card.width - 48, 0),
        const Duration(milliseconds: 240),
      );
    }
    await settle(tester);
    expect(find.text('Reveal reward'), findsNothing);
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
