import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/jobs/data/pending_jobs_repository.dart';
import 'package:kaylo_partner/features/jobs/data/supabase_jobs_repository.dart';
import 'package:kaylo_partner/features/jobs/domain/cash_position.dart';
import 'package:kaylo_partner/features/jobs/domain/job.dart';

Map<String, dynamic> row({
  String status = 'requested',
  String id = 'booking-1',
}) => {
  'booking_id': id,
  'service_name': 'Plumbing',
  'service_icon': 'plumbing',
  'customer_name': 'Test customer',
  'customer_phone': '',
  'address': 'Test address',
  'scheduled_at': '2026-10-10T10:00:00+05:30',
  'payout': 425,
  'notes': 'Leaking tap',
  'status': status,
};

void main() {
  test('real projection preserves booking data and never invents distance', () {
    final job = partnerJobFromRow(row(status: 'on_the_way'));
    expect(job.id, 'booking-1');
    expect(job.serviceName, 'Plumbing');
    expect(job.customerPhone, isEmpty);
    expect(job.distanceKm, isNull);
    expect(job.stage, JobStage.onTheWay);
    expect(job.payout, 425);
    expect(job.scheduledAt.toUtc(), DateTime.parse('2026-10-10T04:30:00Z'));
    expect(
      () => partnerJobFromRow(row(status: 'unexpected')),
      throwsFormatException,
    );
    expect(
      () => partnerJobFromRow(row()..['payout'] = -1),
      throwsFormatException,
    );
  });

  test(
    'jobs, incoming and history listeners share one initial backend read',
    () async {
      var loads = 0;
      final pending = Completer<List<Map<String, dynamic>>>();
      final repo = SupabaseJobsRepository(
        initiallyOnline: true,
        loadRows: () {
          loads++;
          return pending.future;
        },
      );
      addTearDown(repo.dispose);
      final all = repo.watchJobs().first;
      final incoming = repo.watchIncomingRequests().first;
      final history = repo.watchHistory().first;
      await Future<void>.delayed(Duration.zero);
      expect(loads, 1);
      pending.complete([row(), row(id: 'booking-2', status: 'completed')]);
      expect((await all).length, 2);
      expect((await incoming).single.id, 'booking-1');
      expect((await history).single.id, 'booking-2');
    },
  );

  test('a booking change during a read is not lost', () async {
    var loads = 0;
    final initial = Completer<List<Map<String, dynamic>>>();
    final changes = StreamController<void>.broadcast(sync: true);
    final repo = SupabaseJobsRepository(
      initiallyOnline: true,
      changes: changes.stream,
      loadRows: () async {
        loads++;
        return loads == 1 ? await initial.future : [row(status: 'accepted')];
      },
    );
    final seen = <List<Job>>[];
    final subscription = repo.watchJobs().listen(seen.add);
    await Future<void>.delayed(Duration.zero);
    changes.add(null);
    initial.complete([row()]);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(loads, 2);
    expect(seen.last.single.stage, JobStage.accepted);
    await subscription.cancel();
    repo.dispose();
    await changes.close();
  });

  test(
    'detail uses only the authenticated projection and has no sample fallback',
    () async {
      final repo = SupabaseJobsRepository(
        initiallyOnline: false,
        loadRows: () async => [row(id: 'real-booking')],
      );
      addTearDown(repo.dispose);
      expect((await repo.getJobById('real-booking'))?.id, 'real-booking');
      expect(await repo.getJobById('sample-job'), isNull);
      expect(repo.supportsJobActions, isFalse);
      for (final action in [
        repo.acceptJob,
        repo.rejectJob,
        repo.advanceJob,
        repo.cancelJob,
      ]) {
        await expectLater(
          action('real-booking'),
          throwsA(isA<LiveJobsPending>()),
        );
      }
    },
  );

  test(
    'backend failures reach subscribers and a fresh request can recover',
    () async {
      var fail = true;
      final repo = SupabaseJobsRepository(
        initiallyOnline: false,
        loadRows: () async {
          if (fail) throw StateError('backend offline');
          return [row()];
        },
      );
      addTearDown(repo.dispose);
      await expectLater(repo.watchJobs().first, throwsA(anything));
      fail = false;
      expect((await repo.getJobs()).single.id, 'booking-1');
    },
  );

  test('actions call the stage RPCs and re-read the feed', () async {
    final calls = <(String, Map<String, dynamic>?)>[];
    var status = 'requested';
    var loads = 0;
    final repo = SupabaseJobsRepository(
      initiallyOnline: true,
      loadRows: () async {
        loads++;
        return [row(status: status)];
      },
      rpc: (function, {params}) async {
        calls.add((function, params));
        if (function == 'worker_advance_booking') {
          status = params!['p_stage'] as String;
        }
        return null;
      },
    );
    addTearDown(repo.dispose);
    expect(repo.supportsJobActions, isTrue);
    await repo.acceptJob('booking-1');
    expect(calls.single.$1, 'worker_advance_booking');
    expect(calls.single.$2, {
      'p_booking_id': 'booking-1',
      'p_stage': 'accepted',
    });
    expect(loads, 1);
    expect((await repo.getJobs()).single.stage, JobStage.accepted);
    await repo.advanceJob('booking-1');
    expect(calls.last.$2!['p_stage'], 'on_the_way');
    await repo.advanceJob('booking-1');
    expect(calls.last.$2!['p_stage'], 'arrived');
    await repo.cancelJob('booking-1');
    expect(calls.last.$2!['p_stage'], 'cancelled');
    await repo.advanceJob('booking-1');
    expect(calls.length, 4, reason: 'a finished job has no next stage');
  });

  test('cash collection and settlement reach the backend ledger', () async {
    final calls = <(String, Map<String, dynamic>?)>[];
    var due = 0;
    final repo = SupabaseJobsRepository(
      initiallyOnline: true,
      loadRows: () async => [row(status: 'in_progress')],
      rpc: (function, {params}) async {
        calls.add((function, params));
        switch (function) {
          case 'confirm_cash_collected':
            due = 150;
          case 'settle_cash_due':
            due = 0;
          case 'my_cash_position':
            return {
              'cash_in_hand': due == 0 ? 0 : 1000,
              'commission_due': due,
              'limit': 2000,
              'rate': '0.15',
            };
        }
        return null;
      },
    );
    addTearDown(repo.dispose);
    final positions = <CashPosition>[];
    final sub = repo.watchCashPosition().listen(positions.add);
    addTearDown(sub.cancel);
    await Future<void>.delayed(Duration.zero);
    expect(positions.single, CashPosition.none);
    await repo.markCashCollected('booking-1', amount: 1000);
    await Future<void>.delayed(Duration.zero);
    expect(
      calls.map((c) => c.$1).where((f) => f != 'my_cash_position'),
      ['confirm_cash_collected'],
    );
    expect(calls[1].$2, {'p_booking_id': 'booking-1', 'p_amount': 1000});
    expect(positions.last.dueToKaylo, 150);
    expect(positions.last.cashInHand, 1000);
    expect(positions.last.canAcceptCash, isTrue);
    await repo.settleCashDue(reference: 'upi-1');
    await Future<void>.delayed(Duration.zero);
    expect(calls.map((c) => c.$1), contains('settle_cash_due'));
    expect(positions.last, CashPosition.none);
    expect(
      () => CashPosition.fromJson({'cash_in_hand': -1}),
      throwsFormatException,
    );
  });

  test('without an rpc every action still reports live jobs pending', () async {
    final repo = SupabaseJobsRepository(
      initiallyOnline: true,
      loadRows: () async => [row()],
    );
    addTearDown(repo.dispose);
    expect(repo.supportsJobActions, isFalse);
    await expectLater(
      repo.markCashCollected('booking-1'),
      throwsA(isA<LiveJobsPending>()),
    );
    await expectLater(repo.settleCashDue(), throwsA(isA<LiveJobsPending>()));
    await expectLater(
      repo.watchCashPosition().first,
      throwsA(isA<LiveJobsPending>()),
    );
  });
}
