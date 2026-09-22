import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../application/messages_providers.dart';
import '../../domain/chat_models.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ConversationScreen({super.key, required this.threadId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _controller = TextEditingController();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final canSend = _controller.text.trim().isNotEmpty;
      if (canSend != _canSend) setState(() => _canSend = canSend);
    });
    // Opening the thread clears its unread badge on the list.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(currentUserIdProvider) ?? '';
      await ref
          .read(messagesRepositoryProvider)
          .markThreadRead(widget.threadId, userId);
      ref.invalidate(chatThreadsProvider);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    KayloFeedback.tap();
    _controller.clear();
    final userId = ref.read(currentUserIdProvider) ?? '';
    await ref
        .read(messagesRepositoryProvider)
        .sendMessage(widget.threadId, userId, text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thread = ref.watch(chatThreadProvider(widget.threadId));
    final messages = ref.watch(chatMessagesProvider(widget.threadId));
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: thread.maybeWhen(
          data: (t) => Row(
            children: [
              AvatarCircle(fallbackText: t.workerName, radius: 18),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.workerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: t.isOnline ? AppColors.success : secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.isOnline ? l10n.online : l10n.offline,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: secondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          orElse: () => const SizedBox.shrink(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.noMessagesInThread,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: secondary),
                    ),
                  );
                }
                // Reversed list keeps the newest message pinned to the
                // bottom without any scroll bookkeeping.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.m,
                    AppSpacing.l,
                    AppSpacing.m,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) =>
                      _Bubble(message: list[list.length - 1 - index]),
                );
              },
              loading: () => const Center(child: KayloLoader()),
              error: (error, _) => ErrorState(
                title: l10n.somethingWentWrong,
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(chatMessagesProvider(widget.threadId)),
              ),
            ),
          ),
          _Composer(controller: _controller, canSend: _canSend, onSend: _send),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;

  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mine = message.isMine;
    final textColor = mine
        ? Colors.white
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);
    final metaColor = mine
        ? Colors.white.withValues(alpha: 0.75)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary);

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.s),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.m,
        ),
        decoration: BoxDecoration(
          color: mine
              ? AppColors.brandPrimary
              : (isDark ? AppColors.surfaceDark : AppColors.surface),
          border: mine
              ? null
              : Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: mine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textColor, height: 1.35),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.formatTimeOfDay(TimeOfDay.fromDateTime(message.sentAt)),
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: metaColor),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 15,
                    color: message.isRead ? Colors.white : metaColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.m,
        AppSpacing.s,
        AppSpacing.m,
        AppSpacing.s,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: l10n.typeMessage,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.l,
                    vertical: AppSpacing.m,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: canSend ? 1 : 0.5,
              child: Material(
                color: AppColors.brandPrimary,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: canSend ? onSend : null,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
