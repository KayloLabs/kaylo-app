import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../auth/application/current_user_provider.dart';
import '../data/mock_notifications_repository.dart';
import '../data/supabase_notifications_repository.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  if (useMockData) {
    return MockNotificationsRepository();
  }
  return SupabaseNotificationsRepository(ref.watch(supabaseClientProvider));
});

/// Newest first.
final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) async {
    final userId = ref.watch(currentUserIdProvider);
    if (userId == null) return const [];
    final items = await ref
        .watch(notificationsRepositoryProvider)
        .getNotifications(userId);
    return [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  },
);

/// Unread count for the dashboard bell; zero while loading or signed out.
final unreadNotificationsCountProvider = Provider.autoDispose<int>((ref) {
  return ref
          .watch(notificationsProvider)
          .whenOrNull(data: (items) => items.where((n) => !n.isRead).length) ??
      0;
});

final notificationsControllerProvider = Provider<NotificationsController>((
  ref,
) {
  return NotificationsController(ref);
});

class NotificationsController {
  final Ref _ref;

  NotificationsController(this._ref);

  Future<void> markRead(String id) async {
    await _ref.read(notificationsRepositoryProvider).markRead(id);
    _ref.invalidate(notificationsProvider);
  }

  Future<void> markAllRead() async {
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;
    await _ref.read(notificationsRepositoryProvider).markAllRead(userId);
    _ref.invalidate(notificationsProvider);
  }
}
