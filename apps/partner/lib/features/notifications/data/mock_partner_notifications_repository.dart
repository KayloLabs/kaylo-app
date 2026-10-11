import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../jobs/domain/job.dart';
import '../../jobs/domain/jobs_repository.dart';
import '../domain/partner_notification.dart';
import '../domain/partner_notifications_repository.dart';

class MockPartnerNotificationsRepository
    implements PartnerNotificationsRepository {
  final SharedPreferences prefs;
  final String _readKey;
  final _changes = StreamController<List<PartnerNotification>>.broadcast();
  final _items = <PartnerNotification>[];
  final _seen = <String, JobStage>{};
  late final StreamSubscription<List<Job>> _subscription;
  late Set<String> _read;
  MockPartnerNotificationsRepository(
    JobsRepository jobs,
    this.prefs, {
    String identity = 'demo',
  }) : _readKey = 'partner.alerts.read.$identity' {
    _read = (prefs.getStringList(_readKey) ?? []).toSet();
    _subscription = jobs.watchJobs().listen(
      _onJobs,
      onError: _changes.addError,
    );
  }
  void _onJobs(List<Job> jobs) {
    for (final job in jobs) {
      final old = _seen[job.id];
      _seen[job.id] = job.stage;
      if (old == job.stage || old == null && !job.isRequested) continue;
      final type = job.isRequested
          ? PartnerNotificationType.request
          : PartnerNotificationType.job;
      final key = type == PartnerNotificationType.request
          ? 'partner.notify_requests'
          : 'partner.notify_jobs';
      if (!(prefs.getBool(key) ?? true)) continue;
      final id = '${job.id}:${job.stage.name}';
      if (_items.any((n) => n.id == id)) continue;
      _items.insert(
        0,
        PartnerNotification(
          id: id,
          title: '',
          body: '',
          type: type,
          createdAt: DateTime.now(),
          isRead: _read.contains(id),
          jobId: job.id,
          event: job.stage.name,
          details: {
            'service': job.serviceName,
            'distance': job.distanceKm?.toStringAsFixed(1) ?? '',
          },
        ),
      );
    }
    if (!_changes.isClosed) _changes.add(List.unmodifiable(_items));
  }

  @override
  int get unreadCount => _items.where((n) => !n.isRead).length;
  @override
  Stream<List<PartnerNotification>> watchAll() => Stream.multi((sink) {
    final sub = _changes.stream.listen(
      sink.add,
      onError: sink.addError,
      onDone: sink.close,
    );
    sink.add(List.unmodifiable(_items));
    sink.onCancel = sub.cancel;
  });
  @override
  Future<void> markRead(String id) async {
    final index = _items.indexWhere((n) => n.id == id);
    if (index < 0) return;
    _read.add(id);
    await prefs.setStringList(_readKey, _read.toList());
    if (_changes.isClosed) return;
    _items[index] = _items[index].copyWith(isRead: true);
    _changes.add(List.unmodifiable(_items));
  }

  @override
  Future<void> markAllRead() async {
    _read.addAll(_items.map((n) => n.id));
    await prefs.setStringList(_readKey, _read.toList());
    if (_changes.isClosed) return;
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
    _changes.add(List.unmodifiable(_items));
  }

  @override
  void dispose() {
    _subscription.cancel();
    _changes.close();
  }
}
