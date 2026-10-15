import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/booking/application/bookings_providers.dart';
import 'package:kaylo/features/booking/data/booking_updates.dart';
import 'package:kaylo/features/booking/data/mock_bookings_repository.dart';
import 'package:kaylo/features/booking/domain/bookings_repository.dart';
import 'package:kaylo_core/models/booking.dart';

Booking booking(WorkerStage stage) => Booking(
  id: 'sync-job',
  userId: 'person-1',
  serviceId: 'service-1',
  scheduledAt: DateTime(2026, 10, 20),
  totalAmount: 100,
  workerStage: stage,
  status: switch (stage) {
    WorkerStage.requested => BookingStatus.pending,
    WorkerStage.inProgress => BookingStatus.inProgress,
    WorkerStage.completed => BookingStatus.completed,
    WorkerStage.cancelled => BookingStatus.cancelled,
    _ => BookingStatus.confirmed,
  },
);

class LiveRepository extends MockBookingsRepository
    implements LiveBookingsRepository {
  final events = StreamController<List<Booking>>();
  @override
  Stream<List<Booking>> watchUserBookings(String userId) => events.stream;
}

void main() {
  test('customer list and open detail receive every partner stage', () async {
    final repo = LiveRepository();
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWithValue('person-1'),
        bookingsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    final seen = <WorkerStage>[];
    final listener = container.listen(bookingByIdProvider('sync-job'), (
      _,
      next,
    ) {
      if (next.asData?.value case final Booking value) {
        seen.add(value.workerStage);
      }
    });
    addTearDown(() async {
      listener.close();
      container.dispose();
      await repo.events.close();
    });
    for (final stage in WorkerStage.values.where(
      (s) => s != WorkerStage.cancelled,
    )) {
      repo.events.add([booking(stage)]);
      await Future<void>.delayed(Duration.zero);
      await container.pump();
      expect(
        container.read(userBookingsProvider).requireValue.single.workerStage,
        stage,
      );
      expect(
        container
            .read(bookingByIdProvider('sync-job'))
            .requireValue
            .workerStage,
        stage,
      );
    }
    expect(
      seen,
      WorkerStage.values.where((s) => s != WorkerStage.cancelled).toList(),
    );
  });

  test('change during pending initial load forces another read', () async {
    final events = StreamController<void>(sync: true);
    final initial = Completer<List<Booking>>();
    var reads = 0;
    final seen = <WorkerStage>[];
    final subscription = watchBookingSnapshots(
      load: () async =>
          ++reads == 1 ? await initial.future : [booking(WorkerStage.arrived)],
      changes: events.stream,
    ).listen((rows) => seen.add(rows.single.workerStage));
    events.add(null);
    initial.complete([booking(WorkerStage.accepted)]);
    await Future<void>.delayed(Duration.zero);
    expect(reads, 2);
    expect(seen, [WorkerStage.accepted, WorkerStage.arrived]);
    await subscription.cancel();
    expect(events.hasListener, isFalse);
    await events.close();
  });

  test(
    'fallback recovers from read failure and stops when screen closes',
    () async {
      final events = StreamController<void>();
      var reads = 0;
      final recovered = Completer<void>();
      final errors = <Object>[];
      final subscription =
          watchBookingSnapshots(
            load: () async {
              if (++reads == 1) {
                throw StateError('Temporary connection failure');
              }
              return [booking(WorkerStage.completed)];
            },
            changes: events.stream,
            refreshInterval: const Duration(milliseconds: 10),
          ).listen((rows) {
            if (!recovered.isCompleted) recovered.complete();
          }, onError: errors.add);
      await recovered.future.timeout(const Duration(seconds: 1));
      expect(errors, hasLength(1));
      await subscription.cancel();
      final stoppedAt = reads;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(reads, stoppedAt);
      await events.close();
    },
  );
}
