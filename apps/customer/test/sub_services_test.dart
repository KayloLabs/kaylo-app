import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/home/domain/sub_service.dart';
import 'package:kaylo/features/home/presentation/screens/service_details_screen.dart';
import 'package:kaylo_core/models/service_item.dart';

import 'support/test_app.dart';

void main() {
  test('every service offers four priced add-ons and ids round-trip', () {
    for (final name in [
      'Plumbing',
      'Electrical',
      'House Cleaning',
      'Carpentry',
      'Painting',
      'AC Service',
      'Appliance Repair',
      'Gardening',
    ]) {
      final list = subServicesFor(name);
      expect(list.length, 4, reason: name);
      expect(list.every((s) => s.price > 0), isTrue, reason: name);
    }
    final ids = encodeSubServiceIds(['plumb_tap', 'plumb_drain']);
    expect(ids, 'plumb_tap,plumb_drain');
    final back = subServicesByIds('Plumbing', decodeSubServiceIds(ids));
    expect(back.map((s) => s.id), ['plumb_tap', 'plumb_drain']);
    // A stale or foreign id never adds an unpriced item.
    expect(subServicesByIds('Plumbing', ['elec_fan', 'nonsense']), isEmpty);
    expect(decodeSubServiceIds(null), isEmpty);
  });

  test('the draft total adds the add-ons on top of the visit', () {
    final plumbing = ServiceItem(
      id: '4',
      name: 'Plumbing',
      category: 'home',
      description: '',
      iconPath: '',
      basePrice: 300,
    );
    final draft = FarmBookingDraft(
      service: plumbing,
      date: DateTime(2026, 10, 12),
      slot: FarmTimeSlot.all.first,
      quantity: 1,
      address: 'Thekkedath House, Kaloor',
      addOns: subServicesByIds('Plumbing', ['plumb_tap', 'plumb_pipe']),
      addOnsNote: 'Add-ons: Tap repair, Pipe leakage',
    );
    expect(draft.addOnsTotal, 350);
    expect(draft.total, 650);
    expect(
      draft.bookingNotes.split('\n').first,
      'Add-ons: Tap repair, Pipe leakage',
    );
    expect(draft.copyWith(quantity: 2).total, 950);
  });

  testWidgets('ticking an add-on on the service page raises the price', (
    tester,
  ) async {
    useTallPhone(tester);
    await tester.pumpWidget(
      await testApp(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const ServiceDetailsScreen(serviceId: '4'),
          ),
        ],
      ),
    );
    await settle(tester);
    expect(find.text('Starts from'), findsWidgets);
    expect(find.text('₹300'), findsWidgets);

    await tester.tap(find.textContaining('Tap repair'));
    await settle(tester);
    expect(find.text('Total'), findsWidgets);
    expect(find.text('₹450'), findsWidgets);

    await tester.tap(find.textContaining('Drain cleaning'));
    await settle(tester);
    expect(find.text('₹700'), findsWidgets);
  });
}
