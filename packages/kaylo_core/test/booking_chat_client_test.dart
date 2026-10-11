import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaylo_core/messages/booking_chat_client.dart';

class _Channel extends Fake implements RealtimeChannel {
  final callbacks = <void Function(PostgresChangePayload)>[];
  void Function(RealtimeSubscribeStatus, Object?)? status;
  @override
  RealtimeChannel onPostgresChanges({
    required PostgresChangeEvent event,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    List<PostgresChangeFilter>? filters,
    List<String>? select,
    required void Function(PostgresChangePayload) callback,
  }) {
    callbacks.add(callback);
    return this;
  }

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus, Object?)? callback,
    Duration? timeout,
  ]) {
    status = callback;
    callback?.call(RealtimeSubscribeStatus.subscribed, null);
    return this;
  }

  void changed() {
    for (final callback in callbacks) {
      callback(
        PostgresChangePayload(
          schema: 'public',
          table: 'messages',
          commitTimestamp: DateTime.now(),
          eventType: PostgresChangeEvent.insert,
          newRecord: const {},
          oldRecord: const {},
          errors: null,
        ),
      );
    }
  }
}

class _Client extends SupabaseClient {
  _Client(super.url, super.key, {super.httpClient});
  final channels = <_Channel>[];
  final privateFlags = <bool>[];
  int removed = 0;
  @override
  RealtimeChannel channel(
    String name, {
    RealtimeChannelConfig opts = const RealtimeChannelConfig(),
  }) {
    privateFlags.add(opts.private);
    final c = _Channel();
    channels.add(c);
    return c;
  }

  @override
  Future<String> removeChannel(RealtimeChannel channel) async {
    removed++;
    return 'ok';
  }
}

void main() {
  late _Client db;
  late BookingChatClient chat;
  late List<http.Request> requests;
  dynamic response;
  setUp(() {
    requests = [];
    response = [];
    db = _Client(
      'https://example.supabase.co',
      'public-test-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(response),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    chat = BookingChatClient(db, personId: 'person-id');
  });
  tearDown(() async {
    chat.dispose();
    await db.dispose();
  });
  test('read receipt carries the last rendered message boundary', () async {
    response = null;
    await chat.markRead('room', throughMessageId: 'seen-message');
    expect(requests.single.url.path, '/rest/v1/rpc/chat_mark_read_through');
    expect(jsonDecode(requests.single.body), {
      'p_room_id': 'room',
      'p_message_id': 'seen-message',
    });
  });
  test('thread list is one aggregate RPC regardless of thread count', () async {
    response = List.generate(100, (i) => {'room_id': 'room-$i'});
    expect((await chat.listThreads()).length, 100);
    expect(requests.length, 1);
    expect(requests.single.url.path, '/rest/v1/rpc/chat_threads');
  });
  test(
    'send retains supplied retry ID and never accepts a client sender ID',
    () async {
      response = 'message-id';
      await chat.send('room', 'Hello', clientMessageId: 'retry-id');
      await chat.send('room', 'Hello', clientMessageId: 'retry-id');
      expect(requests.length, 2);
      expect(jsonDecode(requests[0].body), {
        'p_room_id': 'room',
        'p_text': 'Hello',
        'p_client_message_id': 'retry-id',
      });
      expect(requests[0].body, requests[1].body);
    },
  );
  test(
    'typing writes are throttled and explicit stop clears immediately',
    () async {
      response = null;
      await chat.setTyping('room', true);
      await chat.setTyping('room', true);
      await chat.setTyping('room', true);
      expect(requests.length, 1);
      await chat.setTyping('room', false);
      expect(requests.length, 2);
      expect(jsonDecode(requests.last.body), {
        'p_room_id': 'room',
        'p_typing': false,
      });
    },
  );
  test('slow typing heartbeat cannot overtake a later clear', () async {
    final gate = Completer<void>();
    final captured = <http.Request>[];
    final slow = _Client(
      'https://example.supabase.co',
      'key',
      httpClient: MockClient((request) async {
        captured.add(request);
        if (captured.length == 1) await gate.future;
        return http.Response(
          'null',
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    final typing = BookingChatClient(slow, personId: 'person-id');
    final started = typing.setTyping('room', true);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final stopped = typing.setTyping('room', false);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(captured.length, 1);
    gate.complete();
    await Future.wait([started, stopped]);
    expect(captured.map((r) => jsonDecode(r.body)['p_typing']), [true, false]);
    typing.dispose();
    await slow.dispose();
  });
  test(
    'realtime bursts coalesce and reconnect refreshes missed thread data',
    () async {
      final snapshots = <List<Map<String, dynamic>>>[];
      final subscription = chat.watchThreads().listen(snapshots.add);
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(requests.length, 1);
      expect(db.privateFlags, hasLength(1));
      expect(db.privateFlags.single, isTrue);
      response = [
        {'room_id': 'room-new'},
      ];
      for (var i = 0; i < 20; i++) {
        db.channels.single.changed();
      }
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(requests.length, 2);
      expect(snapshots.last.single['room_id'], 'room-new');
      response = [
        {'room_id': 'missed-offline'},
      ];
      db.channels.single.status!(RealtimeSubscribeStatus.subscribed, null);
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(snapshots.last.single['room_id'], 'missed-offline');
      await subscription.cancel();
      expect(db.removed, 1);
    },
  );
  test(
    'messages query is room-scoped and includes server read receipts',
    () async {
      response = [
        {
          'message_id': 'm',
          'room_id': 'room',
          'sender_id': 'other',
          'message': 'Hi',
          'sent_at': '2026-10-10T10:00:00Z',
          'read_at': '2026-10-10T10:00:01Z',
        },
      ];
      final rows = await chat.watchMessages('room').first;
      expect(rows.single['read_at'], isNotNull);
      expect(
        requests.single.url.queryParameters['order'],
        'sent_at.asc.nullslast,message_id.asc.nullslast',
      );
      expect(requests.single.url.queryParameters['room_id'], 'eq.room');
      expect(
        requests.single.url.queryParameters['select'],
        contains('read_at'),
      );
    },
  );
  test('typing expires locally and disconnect clears immediately', () async {
    response = [
      {
        'person_id': 'other',
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(milliseconds: 400))
            .toIso8601String(),
      },
    ];
    final events = <bool>[];
    final subscription = chat.watchTyping('room').listen(events.add);
    await Future<void>.delayed(const Duration(milliseconds: 160));
    expect(events.last, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(events.last, isFalse);
    response = [
      {
        'person_id': 'other',
        'expires_at': DateTime.now()
            .toUtc()
            .add(const Duration(seconds: 8))
            .toIso8601String(),
      },
    ];
    db.channels.single.changed();
    await Future<void>.delayed(const Duration(milliseconds: 160));
    expect(events.last, isTrue);
    db.channels.single.status!(RealtimeSubscribeStatus.channelError, 'offline');
    await Future<void>.delayed(Duration.zero);
    expect(events.last, isFalse);
    await subscription.cancel();
  });
}
