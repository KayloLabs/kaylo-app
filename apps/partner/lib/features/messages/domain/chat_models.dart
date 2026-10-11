import 'package:flutter/foundation.dart';

@immutable
class ChatThread {
  final String id, roomId, customerName, serviceName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool canSend;
  const ChatThread({
    required this.id,
    required this.roomId,
    required this.customerName,
    required this.serviceName,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.canSend = true,
  });
  ChatThread copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
    bool? canSend,
  }) => ChatThread(
    id: id,
    roomId: roomId,
    customerName: customerName,
    serviceName: serviceName,
    lastMessage: lastMessage ?? this.lastMessage,
    lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    unreadCount: unreadCount ?? this.unreadCount,
    canSend: canSend ?? this.canSend,
  );
  factory ChatThread.fromJson(Map<String, dynamic> row) => ChatThread(
    id: row['booking_id'] as String,
    roomId: row['room_id'] as String,
    customerName: row['other_name'] as String? ?? '',
    serviceName: row['service_name'] as String? ?? '',
    lastMessage: row['last_message'] as String?,
    lastMessageAt: DateTime.tryParse(
      row['last_message_at'] as String? ?? '',
    )?.toLocal(),
    unreadCount: (row['unread_count'] as num?)?.toInt() ?? 0,
    canSend: row['can_send'] == true,
  );
}

@immutable
class ChatMessage {
  final String id, threadId, senderId, text;
  final DateTime sentAt;
  final bool isMine, isRead;
  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.isRead = false,
  });
  ChatMessage copyWith({bool? isRead}) => ChatMessage(
    id: id,
    threadId: threadId,
    senderId: senderId,
    text: text,
    sentAt: sentAt,
    isMine: isMine,
    isRead: isRead ?? this.isRead,
  );
}
