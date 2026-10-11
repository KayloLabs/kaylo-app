import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kaylo_core/messages/booking_chat_client.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../domain/chat_models.dart';
import '../domain/messages_repository.dart';

class SupabaseMessagesRepository implements MessagesRepository {
  SupabaseMessagesRepository(this._client);
  final SupabaseClient _client;
  BookingChatClient? _chat;
  BookingChatClient _for(String personId) {
    if (_chat?.personId != personId) {
      _chat?.dispose();
      _chat = BookingChatClient(_client, personId: personId);
    }
    return _chat!;
  }

  ChatThread _thread(Map<String, dynamic> row) => ChatThread(
    id: row['room_id'] as String,
    bookingId: row['booking_id'] as String,
    workerId: row['worker_id'] as String? ?? '',
    workerName: row['other_name'] as String? ?? '',
    workerRole: row['service_name'] as String? ?? '',
    canSend: row['can_send'] == true,
    lastMessage: row['last_message'] as String?,
    lastMessageAt: DateTime.tryParse('${row['last_message_at']}')?.toLocal(),
    unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
  );
  @override
  Future<List<ChatThread>> getThreads(String userId) async =>
      (await _for(userId).listThreads()).map(_thread).toList();
  @override
  Stream<List<ChatThread>> watchThreads(String userId) =>
      _for(userId).watchThreads().map((rows) => rows.map(_thread).toList());
  @override
  Future<String> openBooking(String bookingId, String userId) async =>
      (await _for(userId).openBooking(bookingId))['room_id'] as String;
  @override
  Stream<List<ChatMessage>> watchMessages(String threadId, String userId) =>
      _for(userId)
          .watchMessages(threadId)
          .map(
            (rows) => rows
                .map(
                  (row) => ChatMessage(
                    id: row['message_id'] as String,
                    threadId: threadId,
                    senderId: row['sender_id'] as String,
                    text: row['message'] as String,
                    sentAt: DateTime.parse(row['sent_at'] as String).toLocal(),
                    isMine: row['sender_id'] == userId,
                    isRead: row['read_at'] != null,
                  ),
                )
                .toList(),
          );
  @override
  Future<void> sendMessage(
    String threadId,
    String userId,
    String text, {
    required String clientMessageId,
  }) async {
    try {
      await _for(userId).send(threadId, text, clientMessageId: clientMessageId);
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> markThreadRead(
    String threadId,
    String userId, {
    required String throughMessageId,
  }) => _for(userId).markRead(threadId, throughMessageId: throughMessageId);
  @override
  Stream<bool> watchTyping(String threadId, String userId) =>
      _for(userId).watchTyping(threadId);
  @override
  Future<void> setTyping(String threadId, String userId, bool typing) =>
      _for(userId).setTyping(threadId, typing);
  @override
  void dispose() => _chat?.dispose();
}
