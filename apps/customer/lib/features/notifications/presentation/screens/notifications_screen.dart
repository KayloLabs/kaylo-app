import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/notifications_providers.dart';
import '../../domain/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () {
                KayloFeedback.tap();
                ref.read(notificationsControllerProvider).markAllRead();
              },
              child: Text(l10n.markAllRead),
            ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: notifications.when(
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: AppSpacing.xxxl),
                  EmptyState(
                    title: l10n.noNotificationsTitle,
                    description: l10n.noNotificationsDescription,
                    icon: Icons.notifications_none_rounded,
                  ),
                ],
              );
            }
            final now = DateTime.now();
            bool isToday(DateTime t) =>
                t.year == now.year && t.month == now.month && t.day == now.day;
            final today = items.where((n) => isToday(n.createdAt)).toList();
            final earlier = items.where((n) => !isToday(n.createdAt)).toList();

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.l,
                AppSpacing.m,
                AppSpacing.l,
                AppSpacing.xxxl,
              ),
              children: [
                if (today.isNotEmpty) ...[
                  SectionHeader(title: l10n.today),
                  const SizedBox(height: AppSpacing.m),
                  for (final n in today) ...[
                    _NotificationTile(notification: n),
                    const SizedBox(height: AppSpacing.m),
                  ],
                  const SizedBox(height: AppSpacing.m),
                ],
                if (earlier.isNotEmpty) ...[
                  SectionHeader(title: l10n.earlier),
                  const SizedBox(height: AppSpacing.m),
                  for (final n in earlier) ...[
                    _NotificationTile(notification: n),
                    const SizedBox(height: AppSpacing.m),
                  ],
                ],
              ],
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (_, _) => const ShimmerBox(
              width: double.infinity,
              height: 92,
              radius: AppRadius.card,
            ),
          ),
          error: (error, _) => ErrorState(
            title: l10n.somethingWentWrong,
            message: error.toString(),
            onRetry: () => ref.invalidate(notificationsProvider),
          ),
        ),
      ),
    );
  }
}

/// "20 min ago" style stamp, coarse on purpose.
String relativeTime(AppLocalizations l10n, DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return l10n.justNow;
  if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
  return l10n.daysAgo(diff.inDays);
}

class _NotificationTile extends ConsumerWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final (icon, color) = switch (notification.type) {
      NotificationType.booking => (
        Icons.event_available_rounded,
        AppColors.brandPrimary,
      ),
      NotificationType.message => (
        Icons.chat_bubble_rounded,
        AppColors.homeAccent,
      ),
      NotificationType.care => (Icons.favorite_rounded, AppColors.careAccent),
      NotificationType.promo => (
        Icons.local_offer_rounded,
        AppColors.secondaryAccent,
      ),
      NotificationType.system => (Icons.info_rounded, AppColors.textSecondary),
    };

    return KayloCard(
      onTap: () {
        KayloFeedback.tap();
        ref.read(notificationsControllerProvider).markRead(notification.id);
        switch (notification.type) {
          case NotificationType.booking:
            context.go(Routes.bookings);
          case NotificationType.message:
            context.go(Routes.messages);
          case NotificationType.care:
            context.go(Routes.careHome);
          case NotificationType.promo:
            context.push(Routes.farm);
          case NotificationType.system:
            break;
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                      ),
                    ),
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(left: AppSpacing.s),
                        decoration: const BoxDecoration(
                          color: AppColors.brandPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notification.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: secondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  relativeTime(l10n, notification.createdAt),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
