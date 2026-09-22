/// Mirrors the free-text `notifications.type` column.
enum NotificationType { booking, message, care, promo, system }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    message: message,
    type: type,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );

  static NotificationType typeFrom(String? raw) => switch (raw) {
    'booking' => NotificationType.booking,
    'message' => NotificationType.message,
    'care' => NotificationType.care,
    'promo' => NotificationType.promo,
    _ => NotificationType.system,
  };
}
