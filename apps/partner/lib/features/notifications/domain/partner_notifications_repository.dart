import 'partner_notification.dart';

abstract class PartnerNotificationsRepository {
  Stream<List<PartnerNotification>> watchAll();
  Future<void> markRead(String id);
  Future<void> markAllRead();
  int get unreadCount;
  void dispose();
}
