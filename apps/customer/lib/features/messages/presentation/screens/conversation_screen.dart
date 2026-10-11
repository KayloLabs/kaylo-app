import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:kaylo_ui/widgets/chat_typing_indicator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../application/messages_providers.dart';
import '../../domain/chat_models.dart';
import '../../domain/messages_repository.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final String threadId;

  const ConversationScreen({super.key, required this.threadId});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  late MessagesRepository _repository;
  late String _userId;
  bool _canSend = false;
  bool _sending = false;
  bool _foreground = true;
  String? _failedText;
  String? _messageId;
  String? _lastRead;

  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _scroll.addListener(_scheduleRead);
    _repository = ref.read(messagesRepositoryProvider);
    _userId = ref.read(currentUserIdProvider) ?? '';
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(() {
      final canSend = _controller.text.trim().isNotEmpty;
      if (canSend != _canSend && mounted) setState(() => _canSend = canSend);
      unawaited(_setTyping(canSend && !_sending && _foreground));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _markRead();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _setTyping(bool typing) async {
    try {
      await _repository.setTyping(widget.threadId, _userId, typing);
    } catch (_) {
      /* Typing is transient; sending remains independently retryable. */
    }
  }

  void _scheduleRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _markRead();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _markRead() async {
    if (!mounted ||
        !_foreground ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        !_scroll.hasClients ||
        _scroll.position.extentBefore > 2 ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    final unread = ref
        .read(chatMessagesProvider(widget.threadId))
        .value
        ?.where((m) => !m.isMine && !m.isRead)
        .lastOrNull;
    if (unread == null || unread.id == _lastRead) return;
    _lastRead = unread.id;
    try {
      await _repository.markThreadRead(
        widget.threadId,
        _userId,
        throughMessageId: unread.id,
      );
    } catch (_) {
      _lastRead = null;
    } // Retry when the stream catches up after reconnecting.
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      _lastRead = null;
      _scheduleRead();
    } else {
      unawaited(_setTyping(false));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_setTyping(false));
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    if (ref.read(chatThreadProvider(widget.threadId)).value?.canSend != true) {
      return;
    }
    if (_failedText != text || _messageId == null) {
      _messageId = const Uuid().v4();
    }
    _failedText = text;
    setState(() => _sending = true);
    KayloFeedback.tap();
    final sendingRepository = _repository;
    try {
      await sendingRepository.sendMessage(
        widget.threadId,
        _userId,
        text,
        clientMessageId: _messageId!,
      );
      if (!mounted || !identical(sendingRepository, _repository)) return;
      if (_controller.text.trim() == text) _controller.clear();
      _failedText = null;
      _messageId = null;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.chatSendFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextRepository = ref.watch(messagesRepositoryProvider);
    final nextUserId = ref.watch(currentUserIdProvider) ?? '';
    if (!identical(_repository, nextRepository) || _userId != nextUserId) {
      _repository = nextRepository;
      _userId = nextUserId;
      _lastRead = null;
      _failedText = null;
      _messageId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _controller.clear();
        setState(() {
          _sending = false;
          _canSend = false;
        });
      });
    }
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final thread = ref.watch(chatThreadProvider(widget.threadId));
    final messages = ref.watch(chatMessagesProvider(widget.threadId));
    final typing =
        ref.watch(chatTypingProvider(widget.threadId)).value ?? false;
    final writable = thread.value?.canSend ?? false;
    ref.listen(chatMessagesProvider(widget.threadId), (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_markRead());
      });
    });
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
      body: thread.hasError
          ? ErrorState(
              title: l10n.somethingWentWrong,
              message: l10n.chatLoadFailed,
              onRetry: () {
                ref.invalidate(chatThreadsProvider);
                ref.invalidate(chatMessagesProvider(widget.threadId));
              },
            )
          : Column(
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
                        controller: _scroll,
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
                ChatTypingIndicator(
                  label: l10n.chatTyping,
                  visible: typing && writable,
                ),
                if (writable)
                  _Composer(
                    controller: _controller,
                    canSend: _canSend && !_sending,
                    sending: _sending,
                    onSend: _send,
                  )
                else if (thread.hasValue)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Text(
                        l10n.chatReadOnly,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: secondary),
                      ),
                    ),
                  ),
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
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.canSend,
    required this.sending,
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
                readOnly: sending,
                maxLength: 4000,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  counterText: '',
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
                  child: Semantics(
                    button: true,
                    label: l10n.sendMessage,
                    enabled: canSend,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: sending
                          ? const Padding(
                              padding: EdgeInsets.all(15),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                    ),
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
