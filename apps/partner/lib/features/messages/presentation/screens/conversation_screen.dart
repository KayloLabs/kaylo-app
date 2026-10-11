import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/chat_typing_indicator.dart';
import '../../../../core/widgets/partner_load_error.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/messages_providers.dart';
import '../../domain/chat_models.dart';
import '../../domain/messages_repository.dart';

class PartnerConversationScreen extends ConsumerStatefulWidget {
  final String jobId;
  const PartnerConversationScreen({super.key, required this.jobId});
  @override
  ConsumerState<PartnerConversationScreen> createState() =>
      _ConversationState();
}

class _ConversationState extends ConsumerState<PartnerConversationScreen>
    with WidgetsBindingObserver {
  final _text = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  Timer? _typingStop;
  PartnerMessagesRepository? _repo;
  bool _sending = false, _failed = false, _foreground = true;
  String? _pendingText, _pendingId, _readSignature;
  @override
  void initState() {
    super.initState();
    _foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    _scroll.addListener(_scheduleRead);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      _typingStop?.cancel();
      unawaited(
        _repo?.setTyping(widget.jobId, false).catchError((Object _) {}) ??
            Future.value(),
      );
    } else {
      _scheduleRead();
    }
  }

  void _scheduleRead() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _markRead();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _markRead() {
    if (!mounted ||
        !_foreground ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed ||
        !_scroll.hasClients ||
        _scroll.position.extentBefore > 2 ||
        ModalRoute.of(context)?.isCurrent == false) {
      return;
    }
    final rows =
        ref.read(partnerChatMessagesProvider(widget.jobId)).asData?.value ??
        const <ChatMessage>[];
    final unread = rows.where((m) => !m.isMine && !m.isRead).lastOrNull;
    if (unread == null || unread.id == _readSignature) return;
    _readSignature = unread.id;
    unawaited(
      _repo
              ?.markThreadRead(widget.jobId, throughMessageId: unread.id)
              .catchError((Object _) {
                _readSignature = null;
              }) ??
          Future.value(),
    );
  }

  void _changed(String value) {
    setState(() => _failed = false);
    _typingStop?.cancel();
    unawaited(
      _repo
              ?.setTyping(widget.jobId, value.trim().isNotEmpty)
              .catchError((Object _) {}) ??
          Future.value(),
    );
    _typingStop = Timer(
      const Duration(milliseconds: 1600),
      () => unawaited(
        _repo?.setTyping(widget.jobId, false).catchError((Object _) {}) ??
            Future.value(),
      ),
    );
  }

  Future<void> _send([String? quickReply]) async {
    final text = (quickReply ?? _text.text).trim();
    final repo = _repo;
    if (text.isEmpty || _sending || repo == null) return;
    if (_pendingText != text) {
      _pendingText = text;
      _pendingId = newClientMessageId();
    }
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await repo.sendMessage(widget.jobId, text, clientMessageId: _pendingId!);
      if (!mounted) return;
      if (quickReply == null && _text.text.trim() == text) _text.clear();
      _pendingText = null;
      _pendingId = null;
      KayloFeedback.soft();
      _typingStop?.cancel();
      unawaited(repo.setTyping(widget.jobId, false).catchError((Object _) {}));
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _typingStop?.cancel();
    unawaited(
      _repo?.setTyping(widget.jobId, false).catchError((Object _) {}) ??
          Future.value(),
    );
    _text.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!,
        scheme = Theme.of(context).colorScheme;
    _repo = ref.watch(partnerMessagesRepositoryProvider);
    final opened = ref.watch(partnerChatThreadProvider(widget.jobId));
    final messages = ref.watch(partnerChatMessagesProvider(widget.jobId));
    final threads =
        ref.watch(partnerChatThreadsProvider).asData?.value ??
        const <ChatThread>[];
    var thread = opened.asData?.value;
    for (final t in threads) {
      if (t.id == widget.jobId) thread = t;
    }
    ref.listen(partnerChatMessagesProvider(widget.jobId), (previous, next) {
      if (next.hasValue) {
        final followLatest =
            !_scroll.hasClients || _scroll.position.extentBefore < 160;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _markRead();
          if (_scroll.hasClients && followLatest) {
            final reduced = MediaQuery.disableAnimationsOf(context);
            if (reduced) {
              _scroll.jumpTo(0);
            } else {
              _scroll
                  .animateTo(
                    0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  )
                  .whenComplete(_markRead);
            }
          }
        });
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (thread != null) ...[
              AvatarCircle(fallbackText: thread.customerName, radius: 19),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    thread?.customerName ?? l.chatMessages,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (thread != null)
                    Text(
                      thread.serviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: opened.hasError
          ? PartnerLoadError(
              message: l.chatLoadFailed,
              onRetry: () {
                ref.invalidate(partnerChatThreadProvider(widget.jobId));
                ref.invalidate(partnerChatMessagesProvider(widget.jobId));
              },
            )
          : Column(
              children: [
                Expanded(
                  child: messages.when(
                    loading: () => const Center(child: KayloLoader()),
                    error: (_, _) => PartnerLoadError(
                      message: l.chatLoadFailed,
                      onRetry: () => ref.invalidate(
                        partnerChatMessagesProvider(widget.jobId),
                      ),
                    ),
                    data: (rows) => rows.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                l.chatStartConversation,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            reverse: true,
                            padding: const EdgeInsets.all(20),
                            itemCount: rows.length,
                            itemBuilder: (context, index) =>
                                _Bubble(message: rows[rows.length - 1 - index]),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ChatTypingIndicator(
                      label: l.chatTyping,
                      visible:
                          thread?.canSend == true &&
                          (ref
                                  .watch(partnerTypingProvider(widget.jobId))
                                  .asData
                                  ?.value ??
                              false),
                    ),
                  ),
                ),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        l.chatSendFailed,
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  ),
                if (thread?.canSend == true)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 42,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                for (final reply in [
                                  l.chatOnMyWay,
                                  l.chatReached,
                                  l.chatLate,
                                  l.chatExactLocation,
                                ])
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 8,
                                    ),
                                    child: ActionChip(
                                      label: Text(reply),
                                      onPressed: _sending
                                          ? null
                                          : () => _send(reply),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('partner-chat-composer'),
                                  controller: _text,
                                  readOnly: _sending,
                                  focusNode: _focus,
                                  minLines: 1,
                                  maxLines: 4,
                                  maxLength: 4000,
                                  onChanged: _changed,
                                  textInputAction: TextInputAction.newline,
                                  decoration: InputDecoration(
                                    hintText: l.chatMessageHint,
                                    counterText: '',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                key: const Key('partner-chat-send'),
                                tooltip: l.chatSend,
                                onPressed: _sending || _text.text.trim().isEmpty
                                    ? null
                                    : () => _send(),
                                icon: _sending
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_upward_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else if (thread != null)
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        l.chatReadOnly,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
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
    final scheme = Theme.of(context).colorScheme,
        l = AppLocalizations.of(context)!;
    return Align(
      alignment: message.isMine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.77,
        ),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
        decoration: BoxDecoration(
          color: message.isMine
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(18),
            topEnd: const Radius.circular(18),
            bottomStart: Radius.circular(message.isMine ? 18 : 5),
            bottomEnd: Radius.circular(message.isMine ? 5 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              message.text,
              style: TextStyle(
                color: message.isMine
                    ? scheme.onPrimaryContainer
                    : scheme.onSurface,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  MaterialLocalizations.of(
                    context,
                  ).formatTimeOfDay(TimeOfDay.fromDateTime(message.sentAt)),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                if (message.isMine) ...[
                  const SizedBox(width: 5),
                  Tooltip(
                    message: message.isRead ? l.chatRead : l.chatSent,
                    child: Icon(
                      message.isRead
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 16,
                      color: message.isRead
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
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
