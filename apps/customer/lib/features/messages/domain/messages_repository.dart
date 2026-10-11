import 'chat_models.dart';

abstract class MessagesRepository {
  Future<List<ChatThread>> getThreads(String userId);
  Stream<List<ChatThread>> watchThreads(String userId);
  Future<String> openBooking(String bookingId, String userId);
  Stream<List<ChatMessage>> watchMessages(String threadId, String userId);
  Future<void> sendMessage(
    String threadId,
    String userId,
    String text, {
    required String clientMessageId,
  });
  Future<void> markThreadRead(
    String threadId,
    String userId, {
    required String throughMessageId,
  });
  Stream<bool> watchTyping(String threadId, String userId);
  Future<void> setTyping(String threadId, String userId, bool typing);
  void dispose();
}
