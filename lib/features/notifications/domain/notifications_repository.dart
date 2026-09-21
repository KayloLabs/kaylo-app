import 'app_notification.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> getNotifications(String userId);
  Future<void> markRead(String notificationId);
  Future<void> markAllRead(String userId);
}
