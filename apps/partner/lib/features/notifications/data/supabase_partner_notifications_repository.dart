import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/partner_notification.dart';
import '../domain/partner_notifications_repository.dart';

class SupabasePartnerNotificationsRepository
    implements PartnerNotificationsRepository {
  final SupabaseClient client;
  final String personId;
  final SharedPreferences prefs;
  final _changes = StreamController<List<PartnerNotification>>.broadcast();
  RealtimeChannel? _channel;
  Timer? _timer;
  List<PartnerNotification>? _items;
  bool _disposed = false;
  Future<void>? _loading;
  bool _reloadAfterPending = false;
  String? _preferences;
  SupabasePartnerNotificationsRepository(
    this.client, {
    required this.personId,
    required this.prefs,
  });
  @override
  int get unreadCount => _items?.where((n) => !n.isRead).length ?? 0;
  Future<void> _refresh() {
    if (_disposed) return Future.value();
    if (_loading != null) {
      _reloadAfterPending = true;
      return _loading!;
    }
    return _loading = _load().whenComplete(() {
      _loading = null;
      if (_reloadAfterPending && !_disposed) {
        _reloadAfterPending = false;
        unawaited(_refresh());
      }
    });
  }

  Future<void> _load() async {
    try {
      final requests = prefs.getBool('partner.notify_requests') ?? true,
          jobs = prefs.getBool('partner.notify_jobs') ?? true,
          payouts = prefs.getBool('partner.notify_payouts') ?? true;
      final signature = '$requests/$jobs/$payouts';
      if (_preferences != signature) {
        await client.rpc(
          'set_partner_notification_preferences',
          params: {
            'p_requests': requests,
            'p_jobs': jobs,
            'p_payouts': payouts,
          },
        );
        _preferences = signature;
      }
      final rows = await client
          .from('notifications')
          .select(
            'notification_id,title,message,type,is_read,created_at,booking_id',
          )
          .eq('person_id', personId)
          .order('created_at', ascending: false)
          .limit(200);
      if (_disposed) return;
      _items = rows.map(PartnerNotification.fromJson).toList();
      _changes.add(_items!);
    } catch (e, st) {
      if (!_disposed) _changes.addError(e, st);
    }
  }

  @override
  Stream<List<PartnerNotification>> watchAll() => Stream.multi((sink) {
    final sub = _changes.stream.listen(
      sink.add,
      onError: sink.addError,
      onDone: sink.close,
    );
    if (_items != null) sink.add(_items!);
    if (_channel == null) {
      final channel = client.channel(
        'kaylo-chat:$personId:alerts:${DateTime.now().microsecondsSinceEpoch}',
        opts: const RealtimeChannelConfig(private: true),
      );
      for (final event in [
        PostgresChangeEvent.insert,
        PostgresChangeEvent.update,
      ]) {
        channel.onPostgresChanges(
          event: event,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'person_id',
            value: personId,
          ),
          callback: (_) => unawaited(_refresh()),
        );
      }
      _channel = channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          unawaited(_refresh());
        }
      });
      _timer = Timer.periodic(
        const Duration(seconds: 20),
        (_) => unawaited(_refresh()),
      );
    }
    unawaited(_refresh());
    sink.onCancel = sub.cancel;
  });
  @override
  Future<void> markRead(String id) async {
    await client.rpc(
      'mark_my_notifications_read',
      params: {'p_notification_id': id},
    );
    await _refresh();
  }

  @override
  Future<void> markAllRead() async {
    await client.rpc(
      'mark_my_notifications_read',
      params: {'p_notification_id': null},
    );
    await _refresh();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    if (_channel != null) {
      unawaited(
        client
            .removeChannel(_channel!)
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
    _changes.close();
  }
}
