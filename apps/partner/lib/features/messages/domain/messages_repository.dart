import 'dart:math';
import 'chat_models.dart';

abstract class PartnerMessagesRepository {
  Stream<List<ChatThread>> watchThreads();
  Future<ChatThread> openThread(String bookingId);
  Stream<List<ChatMessage>> watchMessages(String bookingId);
  Future<void> sendMessage(
    String bookingId,
    String text, {
    required String clientMessageId,
  });
  Future<void> markThreadRead(
    String bookingId, {
    required String throughMessageId,
  });
  Stream<bool> watchTyping(String bookingId);
  Future<void> setTyping(String bookingId, bool typing);
  void dispose();
}

/// Retained by the composer until acknowledged, so retry cannot duplicate a send.
String newClientMessageId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
