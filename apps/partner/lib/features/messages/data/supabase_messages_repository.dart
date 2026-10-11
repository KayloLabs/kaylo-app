import 'package:kaylo_core/messages/booking_chat_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/chat_models.dart';
import '../domain/messages_repository.dart';

class SupabasePartnerMessagesRepository implements PartnerMessagesRepository {
  final BookingChatClient _client;
  final String personId;
  final Map<String, Future<ChatThread>> _rooms = {};
  SupabasePartnerMessagesRepository(
    SupabaseClient client, {
    required this.personId,
  }) : _client = BookingChatClient(client, personId: personId);
  @override
  Stream<List<ChatThread>> watchThreads() => _client.watchThreads().map(
    (rows) => rows.map(ChatThread.fromJson).toList(),
  );
  @override
  Future<ChatThread> openThread(String bookingId) async {
    try {
      return await (_rooms[bookingId] ??= _client
          .openBooking(bookingId)
          .then(ChatThread.fromJson));
    } catch (_) {
      _rooms.remove(bookingId);
      rethrow;
    }
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String bookingId) async* {
    final thread = await openThread(bookingId);
    yield* _client
        .watchMessages(thread.roomId)
        .map(
          (rows) => rows
              .map(
                (row) => ChatMessage(
                  id: row['message_id'] as String,
                  threadId: bookingId,
                  senderId: row['sender_id'] as String,
                  text: row['message'] as String,
                  sentAt: DateTime.parse(row['sent_at'] as String).toLocal(),
                  isMine: row['sender_id'] == personId,
                  isRead: row['read_at'] != null,
                ),
              )
              .toList(),
        );
  }

  @override
  Future<void> sendMessage(
    String bookingId,
    String text, {
    required String clientMessageId,
  }) async {
    final thread = await openThread(bookingId);
    await _client.send(thread.roomId, text, clientMessageId: clientMessageId);
  }

  @override
  Future<void> markThreadRead(
    String bookingId, {
    required String throughMessageId,
  }) async => _client.markRead(
    (await openThread(bookingId)).roomId,
    throughMessageId: throughMessageId,
  );
  @override
  Stream<bool> watchTyping(String bookingId) async* {
    yield* _client.watchTyping((await openThread(bookingId)).roomId);
  }

  @override
  Future<void> setTyping(String bookingId, bool typing) async =>
      _client.setTyping((await openThread(bookingId)).roomId, typing);
  @override
  void dispose() {
    _client.dispose();
    _rooms.clear();
  }
}
