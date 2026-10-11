import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The same booking conversation transport for customers and approved partners.
/// Database authorization derives membership from the signed-in Firebase token;
/// [personId] is only a realtime filter and never grants access.
class BookingChatClient {
  BookingChatClient(this.client, {required this.personId});
  final SupabaseClient client;
  final String personId;
  final List<_ChatQuery> _queries = [];
  final Map<String, DateTime> _typingWrites = {};
  final Map<String, Timer> _typingIdle = {};
  final Map<String, Future<void>> _typingQueue = {};
  final Set<String> _typingRooms = {};
  bool _disposed = false;
  static int _channelSequence = 0;

  Future<List<Map<String, dynamic>>> listThreads() async =>
      _rows(await client.rpc('chat_threads'));

  Stream<List<Map<String, dynamic>>> watchThreads() =>
      _watch(listThreads, const ['messages', 'chat_rooms', 'bookings']);

  Future<Map<String, dynamic>> openBooking(String bookingId) async {
    _checkOpen();
    final result = await client.rpc(
      'chat_open_booking',
      params: {'p_booking_id': bookingId},
    );
    _refresh();
    return Map<String, dynamic>.from(result as Map);
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String roomId) => _watch(
    () async => _rows(
      await client
          .from('messages')
          .select('message_id,room_id,sender_id,message,sent_at,read_at')
          .eq('room_id', roomId)
          .order('sent_at', ascending: true)
          .order('message_id', ascending: true),
    ),
    const ['messages'],
    roomId: roomId,
  );

  Future<void> send(
    String roomId,
    String text, {
    required String clientMessageId,
  }) async {
    _checkOpen();
    await client.rpc(
      'chat_send',
      params: {
        'p_room_id': roomId,
        'p_text': text,
        'p_client_message_id': clientMessageId,
      },
    );
    await setTyping(roomId, false);
    _refresh();
  }

  Future<void> markRead(
    String roomId, {
    required String throughMessageId,
  }) async {
    _checkOpen();
    await client.rpc(
      'chat_mark_read_through',
      params: {'p_room_id': roomId, 'p_message_id': throughMessageId},
    );
    _refresh();
  }

  Stream<bool> watchTyping(String roomId) {
    StreamSubscription<List<Map<String, dynamic>>>? subscription;
    Timer? expiry;
    bool? last;
    late StreamController<bool> controller;
    void emit(bool value) {
      if (!controller.isClosed && last != value) {
        last = value;
        controller.add(value);
      }
    }

    controller = StreamController<bool>(
      onListen: () {
        subscription =
            _watch(
              () async => _rows(
                await client
                    .from('chat_typing')
                    .select('person_id,expires_at')
                    .eq('room_id', roomId)
                    .neq('person_id', personId),
              ),
              const ['chat_typing'],
              roomId: roomId,
            ).listen(
              (rows) {
                expiry?.cancel();
                final now = DateTime.now().toUtc();
                final future =
                    rows
                        .map((r) => DateTime.tryParse('${r['expires_at']}'))
                        .whereType<DateTime>()
                        .where((date) => date.isAfter(now))
                        .toList()
                      ..sort();
                emit(future.isNotEmpty);
                if (future.isNotEmpty) {
                  expiry = Timer(
                    future.last.difference(now),
                    () => emit(false),
                  );
                }
              },
              onError: (Object error, StackTrace stack) {
                expiry?.cancel();
                emit(false);
              },
              onDone: () {
                expiry?.cancel();
                unawaited(controller.close());
              },
            );
      },
      onCancel: () async {
        expiry?.cancel();
        await subscription?.cancel();
        // Leaving the conversation clears our own indicator immediately if online.
        await _clearTyping(roomId);
      },
    );
    return controller.stream;
  }

  /// Call on composer edits. Writes at most once every three seconds; no
  /// keystrokes or draft text are sent. Eight-second expiry covers disconnects.
  Future<void> setTyping(String roomId, bool typing) async {
    _checkOpen();
    _typingIdle.remove(roomId)?.cancel();
    if (!typing) {
      await _clearTyping(roomId);
      return;
    }
    _typingRooms.add(roomId);
    _typingIdle[roomId] = Timer(const Duration(seconds: 5), () {
      unawaited(_clearTyping(roomId));
    });
    final now = DateTime.now();
    final last = _typingWrites[roomId];
    if (last != null && now.difference(last) < const Duration(seconds: 3)) {
      return;
    }
    _typingWrites[roomId] = now;
    try {
      await _writeTyping(roomId, true);
    } catch (_) {
      _typingWrites.remove(roomId);
      rethrow;
    }
  }

  Future<void> _clearTyping(String roomId) async {
    _typingIdle.remove(roomId)?.cancel();
    _typingWrites.remove(roomId);
    if (!_typingRooms.remove(roomId)) return;
    try {
      await _writeTyping(roomId, false);
    } catch (_) {
      // Offline cleanup is bounded by the server expiry, not a sticky indicator.
    }
  }

  Future<void> _writeTyping(String roomId, bool typing) {
    // Keep true/false writes ordered even when HTTP requests have different
    // latency. A late heartbeat must never restore typing after explicit clear.
    final previous = _typingQueue[roomId] ?? Future<void>.value();
    final operation = previous.catchError((Object _) {}).then((_) async {
      await client.rpc(
        'chat_set_typing',
        params: {'p_room_id': roomId, 'p_typing': typing},
      );
    });
    _typingQueue[roomId] = operation;
    void release() {
      if (identical(_typingQueue[roomId], operation)) {
        _typingQueue.remove(roomId);
      }
    }

    unawaited(
      operation.then(
        (_) => release(),
        onError: (Object error, StackTrace stack) => release(),
      ),
    );
    return operation;
  }

  Stream<List<Map<String, dynamic>>> _watch(
    Future<List<Map<String, dynamic>>> Function() load,
    List<String> tables, {
    String? roomId,
  }) {
    _checkOpen();
    final channel = client.channel(
      'kaylo-chat:$personId:${DateTime.now().microsecondsSinceEpoch}:${_channelSequence++}',
      opts: const RealtimeChannelConfig(private: true),
    );
    late _ChatQuery query;
    query = _ChatQuery(load, () async {
      _queries.remove(query);
      await client.removeChannel(channel);
    });
    for (final table in tables) {
      // PostgreSQL delete events cannot apply row-level authorization to the
      // vanished row. Subscribe only to authorized inserts/updates; periodic
      // snapshots reconcile deletions without leaking another room's IDs.
      for (final event in [
        PostgresChangeEvent.insert,
        PostgresChangeEvent.update,
      ]) {
        channel.onPostgresChanges(
          event: event,
          schema: 'public',
          table: table,
          filter: roomId == null
              ? null
              : PostgresChangeFilter(
                  type: PostgresChangeFilterType.eq,
                  column: 'room_id',
                  value: roomId,
                ),
          callback: (_) => query.refresh(),
        );
      }
    }
    query.onStart = () {
      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) query.refresh();
        if (status == RealtimeSubscribeStatus.channelError ||
            status == RealtimeSubscribeStatus.closed ||
            status == RealtimeSubscribeStatus.timedOut) {
          // Do not claim stale remote typing while the connection is down.
          if (tables.contains('chat_typing')) query.clear();
        }
      });
    };
    _queries.add(query);
    return query.stream;
  }

  void _refresh() {
    for (final query in _queries) {
      query.refresh();
    }
  }

  void _checkOpen() {
    if (_disposed) throw StateError('BookingChatClient is disposed');
  }

  static List<Map<String, dynamic>> _rows(dynamic data) => (data as List)
      .map((row) => Map<String, dynamic>.from(row as Map))
      .toList();

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _typingIdle.values) {
      timer.cancel();
    }
    _typingIdle.clear();
    for (final room in _typingRooms.toList()) {
      unawaited(_clearTyping(room));
    }
    for (final query in _queries.toList()) {
      query.dispose();
    }
    _queries.clear();
  }
}

/// One coalesced query per visible stream, never one request per thread.
/// A periodic catch-up and every successful resubscription recover events that
/// occurred offline. No concurrent snapshots can replace newer results.
class _ChatQuery {
  _ChatQuery(this.load, this.stop) {
    _controller = StreamController<List<Map<String, dynamic>>>.broadcast(
      onListen: () {
        _active = true;
        onStart?.call();
        refresh();
        _poll = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
      },
      onCancel: dispose,
    );
  }
  final Future<List<Map<String, dynamic>>> Function() load;
  final Future<void> Function() stop;
  late final StreamController<List<Map<String, dynamic>>> _controller;
  void Function()? onStart;
  Timer? _poll;
  Timer? _debounce;
  bool _active = false, _loading = false, _again = false, _closed = false;
  Stream<List<Map<String, dynamic>>> get stream => _controller.stream;
  void clear() {
    if (_active && !_closed) _controller.add([]);
  }

  void refresh() {
    if (!_active || _closed) return;
    if (_loading) {
      _again = true;
      return;
    }
    _debounce ??= Timer(const Duration(milliseconds: 80), () {
      _debounce = null;
      unawaited(_load());
    });
  }

  Future<void> _load() async {
    if (!_active || _closed) return;
    _loading = true;
    try {
      final rows = await load();
      if (_active && !_closed) _controller.add(rows);
    } catch (error, stack) {
      if (_active && !_closed) _controller.addError(error, stack);
    } finally {
      _loading = false;
      if (_again) {
        _again = false;
        refresh();
      }
    }
  }

  void dispose() {
    if (_closed) return;
    _closed = true;
    _active = false;
    _poll?.cancel();
    _debounce?.cancel();
    unawaited(stop());
    unawaited(_controller.close());
  }
}
