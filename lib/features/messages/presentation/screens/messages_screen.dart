import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/messages_providers.dart';
import '../../domain/chat_models.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final threads = ref.watch(chatThreadsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(chatThreadsProvider.future),
          child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.l,
            120, // clearance for the bottom nav
          ),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.messages,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.messagesSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            ...threads.when(
              data: (list) => list.isEmpty
                  ? [
                      EmptyState(
                        title: l10n.noMessagesTitle,
                        description: l10n.noMessagesDescription,
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                    ]
                  : [
                      for (final thread in list) ...[
                        _ThreadTile(thread: thread),
                        const SizedBox(height: AppSpacing.m),
                      ],
                    ],
              loading: () => [
                for (var i = 0; i < 3; i++) ...[
                  const ShimmerBox(
                    width: double.infinity,
                    height: 88,
                    radius: AppRadius.card,
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
              ],
              error: (error, _) => [
                ErrorState(
                  title: l10n.somethingWentWrong,
                  message: error.toString(),
                  onRetry: () => ref.invalidate(chatThreadsProvider),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final ChatThread thread;

  const _ThreadTile({required this.thread});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final at = thread.lastMessageAt;
    final now = DateTime.now();
    final stamp = at == null
        ? ''
        : (at.year == now.year && at.month == now.month && at.day == now.day)
            ? loc.formatTimeOfDay(TimeOfDay.fromDateTime(at))
            : loc.formatShortMonthDay(at);

    return KayloCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.m,
      ),
      onTap: () {
        KayloFeedback.tap();
        context.push(Routes.chat(thread.id));
      },
      child: Row(
        children: [
          Stack(
            children: [
              AvatarCircle(fallbackText: thread.workerName, radius: 26),
              if (thread.isOnline)
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.surfaceDark : AppColors.surface,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  thread.workerName,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  thread.workerRole,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  thread.lastMessage ?? l10n.noMessagesInThread,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: secondary,
                        fontWeight: thread.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                stamp,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: secondary),
              ),
              const SizedBox(height: AppSpacing.s),
              if (thread.unreadCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${thread.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, color: secondary),
            ],
          ),
        ],
      ),
    );
  }
}
