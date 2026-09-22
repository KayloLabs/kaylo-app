import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

class MockNotificationsRepository implements NotificationsRepository {
  late final List<AppNotification> _items = [
    AppNotification(
      id: 'n1',
      title: 'Booking confirmed',
      message:
          'Raju K. will arrive on Tuesday at 8:00 AM for Coconut Plucking.',
      type: NotificationType.booking,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
    AppNotification(
      id: 'n2',
      title: 'New message from Raju K.',
      message: 'Sure sir, I will bring full safety rigging and ground nets.',
      type: NotificationType.message,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    AppNotification(
      id: 'n3',
      title: 'Medicine reminder',
      message: 'Vitamin D3 and calcium is due at 1:00 PM.',
      type: NotificationType.care,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n4',
      title: 'Monsoon offer',
      message: 'Tree pruning is 10% off this week. Book before the rains.',
      type: NotificationType.promo,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 3)),
    ),
    AppNotification(
      id: 'n5',
      title: 'Welcome to Kaylo',
      message: 'Trusted help for your home, farm and family, in one place.',
      type: NotificationType.system,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  static const _latency = Duration(milliseconds: 300);

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    await Future.delayed(_latency);
    return List.unmodifiable(_items);
  }

  @override
  Future<void> markRead(String notificationId) async {
    final index = _items.indexWhere((n) => n.id == notificationId);
    if (index != -1) _items[index] = _items[index].copyWith(isRead: true);
  }

  @override
  Future<void> markAllRead(String userId) async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(isRead: true);
    }
  }
}
