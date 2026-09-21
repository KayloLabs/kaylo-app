import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/supabase_providers.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

/// Notifications against the `notifications` table, scoped by RLS to the
/// signed-in person.
class SupabaseNotificationsRepository implements NotificationsRepository {
  final SupabaseClient _client;

  SupabaseNotificationsRepository(this._client);

  @override
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('person_id', userId)
          .order('created_at', ascending: false)
          .limit(100);
      return [
        for (final row in rows)
          AppNotification(
            id: row['notification_id'] as String,
            title: row['title'] as String,
            message: (row['message'] as String?) ?? '',
            type: AppNotification.typeFrom(row['type'] as String?),
            isRead: (row['is_read'] as bool?) ?? false,
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          ),
      ];
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true}).eq('notification_id', notificationId);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<void> markAllRead(String userId) async {
    try {
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('person_id', userId)
          .eq('is_read', false);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }
}
