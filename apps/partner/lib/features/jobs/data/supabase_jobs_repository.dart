import '../domain/booking_destination.dart';
import 'dart:async';

import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/cash_position.dart';
import '../domain/job.dart';
import '../domain/jobs_repository.dart';
import 'pending_jobs_repository.dart';

typedef PartnerJobsLoader = Future<List<Map<String, dynamic>>> Function();
typedef PartnerRpc =
    Future<dynamic> Function(String function, {Map<String, dynamic>? params});

/// This issued worker's actual assigned bookings, plus the stage, cash and
/// settlement actions behind them. Without an [rpc] the feed is read-only and
/// every action reports [LiveJobsPending].
class SupabaseJobsRepository implements JobsRepository {
  SupabaseJobsRepository({
    required PartnerJobsLoader loadRows,
    required bool initiallyOnline,
    Stream<void>? changes,
    PartnerRpc? rpc,
    Duration refreshInterval = const Duration(seconds: 30),
  }) : _loadRows = loadRows,
       _online = initiallyOnline,
       _changes = changes,
       _rpc = rpc,
       _refreshInterval = refreshInterval;

  factory SupabaseJobsRepository.live(
    SupabaseClient client, {
    required String workerId,
    required bool initiallyOnline,
  }) => SupabaseJobsRepository(
    initiallyOnline: initiallyOnline,
    loadRows: () async {
      final results = await Future.wait([
        client.rpc('my_partner_jobs'),
        client.rpc('my_partner_payment_states'),
      ]);
      final payments = {
        for (final row in results[1] as List)
          row['booking_id']: row['payment_status'],
      };
      return (results[0] as List)
          .map(
            (row) => {
              ...Map<String, dynamic>.from(row as Map),
              'payment_status': payments[row['booking_id']] ?? 'pending',
            },
          )
          .toList();
    },
    changes: _bookingChanges(client, workerId),
    rpc: (function, {params}) => client.rpc(function, params: params),
  );

  final PartnerJobsLoader _loadRows;
  final Stream<void>? _changes;
  final PartnerRpc? _rpc;
  final Duration _refreshInterval;
  final _updates = StreamController<List<Job>>.broadcast();
  final _cash = StreamController<CashPosition>.broadcast();
  final _duty = StreamController<bool>.broadcast();
  List<Job>? _snapshot;
  Future<List<Job>>? _pending;
  StreamSubscription<void>? _changesSubscription;
  Timer? _timer;
  int _listeners = 0;
  bool _online;
  bool _disposed = false;
  bool _reloadAfterPending = false;

  @override
  bool get supportsJobActions => _rpc != null;
  @override
  bool get isOnline => _online;

  @override
  Future<List<Job>> getJobs() {
    if (_disposed) return Future.error(StateError('Job feed is closed'));
    if (_pending != null) return _pending!;
    final request = _load().whenComplete(() {
      _pending = null;
      if (_reloadAfterPending && !_disposed) {
        _reloadAfterPending = false;
        unawaited(_refresh());
      }
    });
    _pending = request;
    return request;
  }

  Future<List<Job>> _load() async {
    try {
      final rows = await _loadRows().timeout(const Duration(seconds: 15));
      final jobs = List<Job>.unmodifiable(rows.map(partnerJobFromRow));
      if (!_disposed) {
        _snapshot = jobs;
        _updates.add(jobs);
      }
      return jobs;
    } catch (error) {
      final failure = mapSupabaseError(error);
      if (!_disposed) _updates.addError(failure);
      throw failure;
    }
  }

  Future<void> _refresh() async {
    try {
      await getJobs();
    } catch (_) {
      /* Delivered to the shared stream. */
    }
  }

  void _changed() {
    if (_pending != null) {
      _reloadAfterPending = true;
    } else {
      unawaited(_refresh());
    }
  }

  void _start() {
    _changesSubscription = _changes?.listen(
      (_) => _changed(),
      onError: (Object _) => _changed(),
    );
    _timer = Timer.periodic(_refreshInterval, (_) => _changed());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    unawaited(_changesSubscription?.cancel());
    _changesSubscription = null;
  }

  @override
  Stream<List<Job>> watchJobs() => Stream<List<Job>>.multi((controller) {
    if (_disposed) {
      controller.close();
      return;
    }
    final subscription = _updates.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    final firstListener = _listeners++ == 0;
    if (firstListener) _start();
    final snapshot = _snapshot;
    if (snapshot != null) controller.add(snapshot);
    if (firstListener || snapshot == null) unawaited(_refresh());
    controller.onCancel = () async {
      await subscription.cancel();
      if (--_listeners == 0) _stop();
    };
  });

  @override
  Stream<List<Job>> watchIncomingRequests() =>
      watchJobs().map((jobs) => jobs.where((job) => job.isRequested).toList());
  @override
  Stream<List<Job>> watchHistory() => watchJobs().map(
    (jobs) => jobs.where((job) => job.isCompleted || job.isCancelled).toList(),
  );
  @override
  Stream<Job?> watchActiveJob() => watchJobs().map((jobs) {
    for (final job in jobs) {
      if (job.isActive) return job;
    }
    return null;
  });
  @override
  Future<Job?> getJobById(String id) async {
    final jobs = await getJobs();
    for (final job in jobs) {
      if (job.id == id) return job;
    }
    return null;
  }

  @override
  Stream<bool> watchDutyStatus() => Stream<bool>.multi((controller) {
    controller.add(_online);
    final subscription = _duty.stream.listen(
      controller.add,
      onError: controller.addError,
      onDone: controller.close,
    );
    controller.onCancel = subscription.cancel;
  });
  @override
  Future<void> setDuty(bool online) async {
    _online = online;
    if (!_disposed) _duty.add(online);
  }

  Future<dynamic> _call(String function, Map<String, dynamic> params) async {
    final rpc = _rpc;
    if (rpc == null) throw const LiveJobsPending();
    if (_disposed) throw StateError('Job feed is closed');
    try {
      return await rpc(
        function,
        params: params,
      ).timeout(const Duration(seconds: 15));
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  /// Moves a booking through `worker_advance_booking`, then re-reads the feed
  /// so callers see the server's view before realtime catches up.
  Future<void> _move(String id, JobStage stage) async {
    await _call('worker_advance_booking', {
      'p_booking_id': id,
      'p_stage': backendStage(stage),
    });
    // A poll already in flight may contain the pre-write stage. Wait for it,
    // then read again; never report success on a stale or failed refresh.
    final pending = _pending;
    if (pending != null) {
      try {
        await pending;
      } catch (_) {
        /* Retry the read after the write. */
      }
    }
    await getJobs();
  }

  @override
  Future<void> acceptJob(String id) => _move(id, JobStage.accepted);
  @override
  Future<void> rejectJob(String id) => _move(id, JobStage.cancelled);
  @override
  Future<void> cancelJob(String id) => _move(id, JobStage.cancelled);
  @override
  Future<void> advanceJob(String id) async {
    Job? job;
    for (final candidate in _snapshot ?? const <Job>[]) {
      if (candidate.id == id) job = candidate;
    }
    job ??= await getJobById(id);
    final next = job?.stage.next;
    if (next == null) return;
    await _move(id, next);
  }

  @override
  Future<void> markCashCollected(String id, {double? amount}) async {
    await _call('confirm_cash_collected', {
      'p_booking_id': id,
      'p_amount': ?amount,
    });
    await _refresh();
    await _refreshCash();
  }

  @override
  Future<void> settleCashDue({String? reference}) async {
    await _call('settle_cash_due', {'p_reference': ?reference});
    await _refreshCash();
  }

  @override
  Future<CashPosition> getCashPosition() async {
    final result = await _call('my_cash_position', const {});
    final position = CashPosition.fromJson(
      Map<String, dynamic>.from(result as Map),
    );
    if (!_disposed) _cash.add(position);
    return position;
  }

  Future<void> _refreshCash() async {
    try {
      await getCashPosition();
    } catch (error, stack) {
      if (!_disposed) _cash.addError(error, stack);
    }
  }

  @override
  Stream<CashPosition> watchCashPosition() =>
      Stream<CashPosition>.multi((controller) {
        if (_disposed) {
          controller.close();
          return;
        }
        final subscription = _cash.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
        unawaited(_refreshCash());
        controller.onCancel = subscription.cancel;
      });

  @override
  void dispose() {
    _disposed = true;
    _stop();
    _updates.close();
    _duty.close();
    _cash.close();
    _snapshot = null;
  }
}

/// The stage names `worker_advance_booking` accepts.
String backendStage(JobStage stage) => switch (stage) {
  JobStage.requested => 'requested',
  JobStage.accepted => 'accepted',
  JobStage.onTheWay => 'on_the_way',
  JobStage.arrived => 'arrived',
  JobStage.inProgress => 'in_progress',
  JobStage.completed => 'completed',
  JobStage.cancelled => 'cancelled',
};

Job partnerJobFromRow(Map<String, dynamic> row) {
  final stage = switch (row['status']) {
    'requested' => JobStage.requested,
    'accepted' => JobStage.accepted,
    'on_the_way' => JobStage.onTheWay,
    'arrived' => JobStage.arrived,
    'in_progress' => JobStage.inProgress,
    'completed' => JobStage.completed,
    'cancelled' => JobStage.cancelled,
    _ => throw const FormatException('Unknown booking stage'),
  };
  final payout = (row['payout'] as num).toDouble();
  if (!payout.isFinite || payout < 0) {
    throw const FormatException('Invalid booking payout');
  }
  final notes = row['notes'] as String? ?? '';
  final pin = bookingPin(notes);
  final savedLat = (row['latitude'] as num?)?.toDouble();
  final savedLng = (row['longitude'] as num?)?.toDouble();
  final hasSavedPin =
      savedLat != null &&
      savedLng != null &&
      savedLat.isFinite &&
      savedLng.isFinite &&
      savedLat.abs() <= 90 &&
      savedLng.abs() <= 180;
  return Job(
    id: row['booking_id'] as String,
    serviceName: row['service_name'] as String,
    serviceIcon: row['service_icon'] as String? ?? '',
    customerName: row['customer_name'] as String,
    customerPhone: row['customer_phone'] as String? ?? '',
    addressLine: row['address'] as String? ?? '',
    latitude: hasSavedPin ? savedLat : pin?.latitude,
    longitude: hasSavedPin ? savedLng : pin?.longitude,
    distanceKm: null,
    scheduledAt: DateTime.parse(row['scheduled_at'] as String).toLocal(),
    payout: payout,
    paymentMode: row['payment_mode'] as String? ?? 'online',
    customerPrice: (row['customer_price'] as num?)?.toDouble(),
    paymentStatus: row['payment_status'] as String? ?? 'pending',
    notes: row['notes'] as String? ?? '',
    stage: stage,
  );
}

Stream<void> _bookingChanges(SupabaseClient client, String workerId) {
  RealtimeChannel? channel;
  late StreamController<void> changes;
  changes = StreamController<void>.broadcast(
    onListen: () async {
      // Reuse the existing private-channel policy scoped to the signed-in
      // person. Postgres row delivery still uses booking participant RLS.
      final String? personId;
      try {
        personId = await client.rpc('current_person_id') as String?;
      } catch (_) {
        if (changes.hasListener) changes.add(null);
        return;
      }
      if (personId == null || !changes.hasListener) return;
      final topic = client.channel(
        'kaylo-chat:$personId:partner-jobs:${identityHashCode(changes)}',
        opts: const RealtimeChannelConfig(private: true),
      );
      for (final event in [
        PostgresChangeEvent.insert,
        PostgresChangeEvent.update,
      ]) {
        topic.onPostgresChanges(
          event: event,
          schema: 'public',
          table: 'bookings',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'worker_id',
            value: workerId,
          ),
          callback: (_) {
            if (!changes.isClosed) changes.add(null);
          },
        );
      }
      channel = topic.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed && !changes.isClosed) {
          changes.add(null);
        }
      });
    },
    onCancel: () {
      final current = channel;
      channel = null;
      if (current != null) {
        unawaited(
          client
              .removeChannel(current)
              .then<void>((_) {}, onError: (Object _) {}),
        );
      }
    },
  );
  return changes.stream;
}
