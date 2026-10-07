import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/booking/application/bookings_providers.dart';
import 'package:kaylo/features/booking/data/mock_bookings_repository.dart';
import 'package:kaylo/features/booking/domain/payment_gateway.dart';
import 'package:kaylo/features/booking/domain/payment_choice.dart';
import 'package:kaylo/features/farm/application/farm_providers.dart';
import 'package:kaylo/features/farm/domain/farm_booking_draft.dart';
import 'package:kaylo_core/models/booking.dart';
import 'package:kaylo_core/models/service_item.dart';

class _Bookings extends MockBookingsRepository {
  final rows = <Booking>[];
  @override
  Future<List<Booking>> getUserBookings(String userId) async => [...rows];
  @override
  Future<Booking> createBooking(Booking booking) async {
    final created = booking.copyWith(id: 'b${rows.length + 1}');
    rows.add(created);
    return created;
  }

  @override
  void applyOffer(Booking booking) {
    rows[rows.indexWhere((b) => b.id == booking.id)] = booking;
  }

  @override
  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    final i = rows.indexWhere((b) => b.id == id);
    rows[i] = rows[i].copyWith(status: status);
  }
}

class _Gateway implements PaymentGateway {
  final _Bookings repo;
  final totals = <double>[];
  int calls = 0;
  _Gateway(this.repo);
  @override
  Future<PaymentOutcome> pay({
    required String bookingId,
    String? email,
    String? preferredMethod,
  }) async {
    totals.add(repo.rows.firstWhere((b) => b.id == bookingId).totalAmount);
    return calls++ == 0
        ? const PaymentOutcome.notPaid('Cancelled')
        : const PaymentOutcome.paid();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final draft = FarmBookingDraft(
    service: ServiceItem(
      id: 'plumber',
      name: 'Plumbing',
      category: 'home',
      description: '',
      iconPath: '',
      basePrice: 500,
    ),
    date: DateTime(2026, 10, 4),
    slot: FarmTimeSlot.all.first,
    quantity: 1,
    address: 'Test address',
  );
  test(
    'payment retry keeps one booking and charges the discounted amount once',
    () async {
      final repo = _Bookings();
      final gateway = _Gateway(repo);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('customer'),
          bookingsRepositoryProvider.overrideWithValue(repo),
          paymentGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        farmCheckoutControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(farmCheckoutControllerProvider.future);
      final checkout = container.read(farmCheckoutControllerProvider.notifier);
      expect(
        await checkout.confirm(
          draft: draft,
          method: PaymentChoice.online,
          offerCode: 'FIRST100',
        ),
        isNull,
      );
      final confirmed = await checkout.confirm(
        draft: draft,
        method: PaymentChoice.online,
        offerCode: 'FIRST100',
      );
      expect(repo.rows, hasLength(1));
      expect(gateway.totals, [400, 400]);
      expect(confirmed!.discountAmount, 100);
      expect(confirmed.subtotalAmount, 500);
      expect(confirmed.status, BookingStatus.confirmed);
    },
  );
  test(
    'pay-after-service saves the discounted estimate without opening gateway',
    () async {
      final repo = _Bookings();
      final gateway = _Gateway(repo);
      final container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('customer'),
          bookingsRepositoryProvider.overrideWithValue(repo),
          paymentGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        farmCheckoutControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(farmCheckoutControllerProvider.future);
      final booking = await container
          .read(farmCheckoutControllerProvider.notifier)
          .confirm(
            draft: draft,
            method: PaymentChoice.payAfterService,
            offerCode: 'FIRST100',
          );
      expect(booking!.totalAmount, 400);
      expect(repo.rows.single.offerCode, 'FIRST100');
      expect(gateway.calls, 0);
      expect(booking.status, BookingStatus.pending);
    },
  );
}
