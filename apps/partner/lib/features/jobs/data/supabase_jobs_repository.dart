import 'dart:async';

import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/job.dart';
import '../domain/jobs_repository.dart';
import 'pending_jobs_repository.dart';

typedef PartnerJobsLoader = Future<List<Map<String, dynamic>>> Function();

/// A single read-only feed of this issued worker's actual assigned bookings.
/// Status mutations remain unavailable until the separate job workflow lands.
class SupabaseJobsRepository implements JobsRepository {
  SupabaseJobsRepository({
    required PartnerJobsLoader loadRows,
    required bool initiallyOnline,
    Stream<void>? changes,
    Duration refreshInterval = const Duration(seconds: 30),
  }) : _loadRows = loadRows,
       _online = initiallyOnline,
       _changes = changes,
       _refreshInterval = refreshInterval;

  factory SupabaseJobsRepository.live(
    SupabaseClient client, {
    required String workerId,
    required bool initiallyOnline,
  }) => SupabaseJobsRepository(
    initiallyOnline: initiallyOnline,
    loadRows: () async {
      final result = await client.rpc('my_partner_jobs');
      return (result as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    },
    changes: _bookingChanges(client, workerId),
  );

  final PartnerJobsLoader _loadRows;
  final Stream<void>? _changes;
  final Duration _refreshInterval;
  final _updates = StreamController<List<Job>>.broadcast();
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
  bool get supportsJobActions => false;
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

  @override
  Future<void> acceptJob(String id) async => throw const LiveJobsPending();
  @override
  Future<void> rejectJob(String id) async => throw const LiveJobsPending();
  @override
  Future<void> advanceJob(String id) async => throw const LiveJobsPending();
  @override
  Future<void> cancelJob(String id) async => throw const LiveJobsPending();
  @override
  void dispose() {
    _disposed = true;
    _stop();
    _updates.close();
    _duty.close();
    _snapshot = null;
  }
}

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
  return Job(
    id: row['booking_id'] as String,
    serviceName: row['service_name'] as String,
    serviceIcon: row['service_icon'] as String? ?? '',
    customerName: row['customer_name'] as String,
    customerPhone: row['customer_phone'] as String? ?? '',
    addressLine: row['address'] as String? ?? '',
    distanceKm: null,
    scheduledAt: DateTime.parse(row['scheduled_at'] as String).toLocal(),
    payout: payout,
    notes: row['notes'] as String? ?? '',
    stage: stage,
  );
}

Stream<void> _bookingChanges(SupabaseClient client, String workerId) {
  RealtimeChannel? channel;
  late StreamController<void> changes;
  changes = StreamController<void>.broadcast(
    onListen: () {
      final topic = client.channel(
        'partner-jobs:$workerId:${identityHashCode(changes)}',
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
