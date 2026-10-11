/// One conversation between the customer and a worker. Lives per booking
/// on the backend (`chat_rooms`), and is linked to that exact booking.
class ChatThread {
  final String id;
  final String workerId;
  final String? bookingId;
  final bool canSend;
  final String workerName;
  final String workerRole;
  final bool isOnline;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.workerId,
    this.bookingId,
    this.canSend = true,
    required this.workerName,
    required this.workerRole,
    this.isOnline = false,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  ChatThread copyWith({
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatThread(
      id: id,
      workerId: workerId,
      bookingId: bookingId,
      canSend: canSend,
      workerName: workerName,
      workerRole: workerRole,
      isOnline: isOnline,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class ChatMessage {
  final String id;
  final String threadId;
  final String senderId;
  final String text;
  final DateTime sentAt;
  final bool isMine;

  /// True once the other participant has opened this message.
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.isRead = false,
  });

  ChatMessage copyWith({bool? isRead}) {
    return ChatMessage(
      id: id,
      threadId: threadId,
      senderId: senderId,
      text: text,
      sentAt: sentAt,
      isMine: isMine,
      isRead: isRead ?? this.isRead,
    );
  }
}
