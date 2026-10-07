import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/booking/application/bookings_providers.dart';
import 'package:kaylo/features/booking/data/mock_bookings_repository.dart';
import 'package:kaylo/features/booking/domain/payment_gateway.dart';
import 'package:kaylo/features/booking/domain/payment_choice.dart';
import 'package:kaylo/features/care/application/care_checkout.dart';
import 'package:kaylo/features/farm/application/farm_providers.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo/features/offers/application/offers_providers.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/network/app_failure.dart';

import 'support/test_app.dart';

class _Bookings extends MockBookingsRepository {
  final rows = <Booking>[];
  @override
  Future<List<Booking>> getUserBookings(String userId) async => [...rows];
  @override
  Future<Booking> createBooking(Booking booking) async {
    final row = booking.copyWith(id: 'b${rows.length + 1}');
    rows.add(row);
    return row;
  }

  @override
  void applyOffer(Booking booking) {
    rows[rows.indexWhere((b) => b.id == booking.id)] = booking;
  }

  @override
  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    final index = rows.indexWhere((b) => b.id == id);
    rows[index] = rows[index].copyWith(status: status);
  }
}

class _CancelledGateway implements PaymentGateway {
  final ids = <String>[];
  @override
  Future<PaymentOutcome> pay({
    required String bookingId,
    String? email,
    String? preferredMethod,
  }) async {
    ids.add(bookingId);
    return const PaymentOutcome.notPaid('Payment sheet closed');
  }
}

final _draft = FarmBookingDraft(
  service: ServiceItem(
    id: '4',
    name: 'Plumbing',
    category: 'home',
    description: '',
    iconPath: '',
    basePrice: 500,
  ),
  date: DateTime(2026, 10, 4),
  slot: FarmTimeSlot.all.first,
  quantity: 1,
  address: 'Home',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'rejected coupon releases the unstarted row and allows first-offer retry',
    () async {
      final repo = _Bookings();
      final gateway = _CancelledGateway();
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('customer'),
          bookingsRepositoryProvider.overrideWithValue(repo),
          paymentGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(
        farmCheckoutControllerProvider,
        (_, _) {},
      );
      addTearDown(keepAlive.close);
      await container.read(farmCheckoutControllerProvider.future);
      final checkout = container.read(farmCheckoutControllerProvider.notifier);
      await checkout.confirm(
        draft: _draft,
        method: PaymentChoice.online,
        offerCode: 'INVALID',
      );
      expect(repo.rows.single.status, BookingStatus.cancelled);
      expect(gateway.ids, isEmpty);
      expect(checkout.hasStartedPayment, isFalse);

      await checkout.confirm(
        draft: _draft,
        method: PaymentChoice.online,
        offerCode: 'FIRST100',
      );
      expect(repo.rows, hasLength(2));
      expect(repo.rows.last.totalAmount, 400);
      expect(repo.rows.last.status, BookingStatus.pending);
      expect(gateway.ids, ['b2']);
      expect(checkout.hasStartedPayment, isTrue);
    },
  );

  test(
    'a retry error never cancels a row already sent to the gateway',
    () async {
      final repo = _Bookings();
      final gateway = _CancelledGateway();
      var reject = false;
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('customer'),
          bookingsRepositoryProvider.overrideWithValue(repo),
          paymentGatewayProvider.overrideWithValue(gateway),
          bookingOfferApplierProvider.overrideWith(
            (ref) => (booking, code) async {
              if (reject) throw ServerFailure('Could not check offer');
              return booking;
            },
          ),
        ],
      );
      addTearDown(container.dispose);
      final keepAlive = container.listen(
        farmCheckoutControllerProvider,
        (_, _) {},
      );
      addTearDown(keepAlive.close);
      await container.read(farmCheckoutControllerProvider.future);
      final checkout = container.read(farmCheckoutControllerProvider.notifier);
      await checkout.confirm(draft: _draft, method: PaymentChoice.online);
      reject = true;
      await checkout.confirm(draft: _draft, method: PaymentChoice.online);
      expect(repo.rows, hasLength(1));
      expect(repo.rows.single.status, BookingStatus.pending);
      expect(checkout.hasStartedPayment, isTrue);
    },
  );

  testWidgets(
    'Care coupon rejection releases eligibility and retries one order',
    (tester) async {
      final repo = _Bookings();
      final gateway = _CancelledGateway();
      final checkout = CareCheckout();
      String code = 'INVALID';
      Object? error;
      await tester.pumpWidget(
        await testApp(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => Consumer(
                builder: (context, ref, _) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      try {
                        await checkout.pay(
                          ref,
                          kind: 'doctor',
                          mockAmount: 500,
                          offerCode: code,
                          details: {
                            'date': '2026-10-04',
                            'time': '09:00',
                            'notes': 'Home\nMap: https://maps.example/point',
                            'location_id': 'saved-home',
                          },
                        );
                      } catch (e) {
                        error = e;
                      }
                    },
                    child: const Text('Pay'),
                  ),
                ),
              ),
            ),
          ],
          overrides: [
            bookingsRepositoryProvider.overrideWithValue(repo),
            paymentGatewayProvider.overrideWithValue(gateway),
          ],
        ),
      );
      await tester.tap(find.text('Pay'));
      await settle(tester);
      expect(error, isA<AppFailure>());
      expect(repo.rows.single.status, BookingStatus.cancelled);
      expect(checkout.hasStartedPayment, isFalse);
      code = 'FIRST100';
      await tester.tap(find.text('Pay'));
      await settle(tester);
      expect(repo.rows.last.totalAmount, 400);
      expect(repo.rows.last.locationId, 'saved-home');
      expect(repo.rows.last.notes, contains('Map:'));
      expect(checkout.hasStartedPayment, isTrue);
      await tester.tap(find.text('Pay'));
      await settle(tester);
      expect(repo.rows, hasLength(2));
      expect(gateway.ids, ['b2', 'b2']);
    },
  );
}
