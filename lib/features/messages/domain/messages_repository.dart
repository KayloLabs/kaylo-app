import 'chat_models.dart';

abstract class MessagesRepository {
  Future<List<ChatThread>> getThreads(String userId);

  /// Emits the full message list for a thread, newest last, and again
  /// whenever it changes.
  Stream<List<ChatMessage>> watchMessages(String threadId, String userId);

  Future<void> sendMessage(String threadId, String userId, String text);

  Future<void> markThreadRead(String threadId, String userId);
}
