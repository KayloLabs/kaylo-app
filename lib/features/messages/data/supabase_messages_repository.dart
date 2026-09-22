import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../domain/chat_models.dart';
import '../domain/messages_repository.dart';

/// Conversations against `chat_rooms` and `messages`. A room hangs off a
/// booking, so threads are discovered through the customer's bookings.
class SupabaseMessagesRepository implements MessagesRepository {
  final SupabaseClient _client;

  SupabaseMessagesRepository(this._client);

  @override
  Future<List<ChatThread>> getThreads(String userId) async {
    try {
      final rows = await _client
          .from('bookings')
          .select(
            'booking_id, worker_id, '
            'chat_rooms(room_id), '
            'workers(worker_id, persons(full_name)), '
            'services(service_name)',
          )
          .eq('customer_id', userId);

      final threads = <ChatThread>[];
      for (final row in rows) {
        final roomId = _roomId(row['chat_rooms']);
        if (roomId == null) continue;

        final last = await _client
            .from('messages')
            .select('message, sent_at')
            .eq('room_id', roomId)
            .order('sent_at', ascending: false)
            .limit(1)
            .maybeSingle();

        final worker = row['workers'] as Map<String, dynamic>?;
        final person = worker?['persons'] as Map<String, dynamic>?;
        final service = row['services'] as Map<String, dynamic>?;

        threads.add(
          ChatThread(
            id: roomId,
            workerId: (row['worker_id'] as String?) ?? '',
            workerName: (person?['full_name'] as String?) ?? 'Worker',
            workerRole: (service?['service_name'] as String?) ?? '',
            lastMessage: last?['message'] as String?,
            lastMessageAt: last == null
                ? null
                : DateTime.parse(last['sent_at'] as String).toLocal(),
          ),
        );
      }
      threads.sort((a, b) {
        final at = a.lastMessageAt, bt = b.lastMessageAt;
        if (at == null || bt == null) return 0;
        return bt.compareTo(at);
      });
      return threads;
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  // A unique FK comes back as an object on some PostgREST versions and a
  // single-element list on others.
  String? _roomId(Object? rooms) {
    if (rooms is Map<String, dynamic>) return rooms['room_id'] as String?;
    if (rooms is List && rooms.isNotEmpty) {
      return (rooms.first as Map<String, dynamic>)['room_id'] as String?;
    }
    return null;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId, String userId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['message_id'])
        .eq('room_id', threadId)
        .order('sent_at', ascending: true)
        .map(
          (rows) => [
            for (final row in rows)
              ChatMessage(
                id: row['message_id'] as String,
                threadId: threadId,
                senderId: row['sender_id'] as String,
                text: row['message'] as String,
                sentAt: DateTime.parse(row['sent_at'] as String).toLocal(),
                isMine: row['sender_id'] == userId,
              ),
          ],
        );
  }

  @override
  Future<void> sendMessage(String threadId, String userId, String text) async {
    try {
      await _client.from('messages').insert({
        'room_id': threadId,
        'sender_id': userId,
        'message': text,
      });
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  /// The schema has no read receipts yet, so there is nothing to persist.
  @override
  Future<void> markThreadRead(String threadId, String userId) async {}
}
