import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import '../../../../core/widgets/partner_load_error.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/messages_providers.dart';

class PartnerMessagesScreen extends ConsumerWidget {
  const PartnerMessagesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final threads = ref.watch(partnerChatThreadsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.chatMessages)),
      body: threads.when(
        loading: () => const Center(child: KayloLoader()),
        error: (_, _) => PartnerLoadError(
          message: l.chatLoadFailed,
          onRetry: () => ref.invalidate(partnerChatThreadsProvider),
        ),
        data: (rows) => rows.isEmpty
            ? EmptyState(
                title: l.chatNoMessages,
                description: l.chatNoMessagesBody,
                icon: Icons.chat_bubble_outline_rounded,
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 80),
                itemBuilder: (context, index) {
                  final t = rows[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    leading: AvatarCircle(
                      fallbackText: t.customerName,
                      radius: 24,
                    ),
                    title: Text(
                      t.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.serviceName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          t.lastMessage ?? l.chatStartConversation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (t.lastMessageAt != null)
                          Text(
                            MaterialLocalizations.of(
                              context,
                            ).formatShortMonthDay(t.lastMessageAt!),
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        const SizedBox(height: 6),
                        if (t.unreadCount > 0)
                          Badge.count(count: t.unreadCount),
                      ],
                    ),
                    onTap: () => context.push(Routes.conversation(t.id)),
                  );
                },
              ),
      ),
    );
  }
}
