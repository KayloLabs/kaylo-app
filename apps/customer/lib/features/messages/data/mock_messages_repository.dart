import 'dart:async';

import '../domain/chat_models.dart';
import '../domain/messages_repository.dart';

/// In-memory conversations. A worker replies shortly after every message
/// so the demo feels alive offline; [replyDelay] is short in tests.
class MockMessagesRepository implements MessagesRepository {
  final Duration replyDelay;

  MockMessagesRepository({this.replyDelay = const Duration(seconds: 2)});

  static const _me = 'me';

  final List<ChatThread> _threads = [
    const ChatThread(
      id: 't1',
      bookingId: 'b1',
      workerId: 'w1',
      workerName: 'Raju K.',
      workerRole: 'Coconut climber',
      isOnline: true,
      unreadCount: 2,
    ),
    const ChatThread(
      id: 't2',
      bookingId: 'b2',
      workerId: 'w2',
      workerName: 'Manoj P.',
      workerRole: 'Plumber and farm hand',
      isOnline: false,
    ),
  ];

  late final Map<String, List<ChatMessage>> _messages = {
    't1': [
      _msg(
        't1',
        'w1',
        'Namaskaram! I saw your booking for 10 coconut trees on Wednesday.',
        minutesAgo: 25,
        isMine: false,
      ),
      _msg(
        't1',
        _me,
        'Namaskaram Raju, please bring extra nets for the bunches.',
        minutesAgo: 18,
        isMine: true,
        isRead: true,
      ),
      _msg(
        't1',
        'w1',
        'Sure sir, I will bring full safety rigging and ground nets by 8 AM.',
        minutesAgo: 5,
        isMine: false,
      ),
    ],
    't2': [
      _msg(
        't2',
        'w2',
        'The brush cutter is serviced. Ready for tomorrow morning.',
        minutesAgo: 120,
        isMine: false,
      ),
    ],
  };

  static const _replies = [
    'Noted! I have added this to my checklist for the visit.',
    'Okay, will do. See you at the farm.',
    'Understood. I will call you when I am on the way.',
  ];

  final Map<String, StreamController<List<ChatMessage>>> _controllers = {};
  final List<Timer> _timers = [];
  final _threadChanges = StreamController<void>.broadcast();
  final Map<String, StreamController<bool>> _typingChanges = {};
  final Map<String, int> _pendingReplies = {};
  final Set<String> _sentIds = {};
  int _sent = 0;

  static ChatMessage _msg(
    String threadId,
    String senderId,
    String text, {
    required int minutesAgo,
    required bool isMine,
    bool isRead = false,
  }) {
    return ChatMessage(
      id: '$threadId-$senderId-$minutesAgo',
      threadId: threadId,
      senderId: senderId,
      text: text,
      sentAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      isMine: isMine,
      isRead: isRead,
    );
  }

  StreamController<List<ChatMessage>> _controller(String threadId) =>
      _controllers.putIfAbsent(threadId, StreamController.broadcast);

  void _emit(String threadId) {
    _controller(threadId).add(List.unmodifiable(_messages[threadId] ?? []));
    _threadChanges.add(null);
  }

  @override
  Future<List<ChatThread>> getThreads(String userId) async {
    return [
      for (final thread in _threads)
        if ((_messages[thread.id] ?? const []).isNotEmpty)
          thread.copyWith(
            lastMessage: _messages[thread.id]!.last.text,
            lastMessageAt: _messages[thread.id]!.last.sentAt,
          )
        else
          thread,
    ]..sort((a, b) {
      final at = a.lastMessageAt, bt = b.lastMessageAt;
      if (at == null || bt == null) return 0;
      return bt.compareTo(at);
    });
  }

  @override
  Stream<List<ChatThread>> watchThreads(String userId) =>
      Stream.multi((listener) {
        getThreads(userId).then(listener.addSync);
        final sub = _threadChanges.stream.listen(
          (_) async => listener.add(await getThreads(userId)),
        );
        listener.onCancel = sub.cancel;
      });

  @override
  Future<String> openBooking(String bookingId, String userId) async =>
      _threads.firstWhere((thread) => thread.bookingId == bookingId).id;

  @override
  Stream<bool> watchTyping(String threadId, String userId) =>
      Stream.multi((listener) {
        listener.add((_pendingReplies[threadId] ?? 0) > 0);
        final sub = _typingChanges
            .putIfAbsent(threadId, StreamController<bool>.broadcast)
            .stream
            .listen(listener.add);
        listener.onCancel = sub.cancel;
      });

  @override
  Future<void> setTyping(String threadId, String userId, bool typing) async {}

  @override
  Stream<List<ChatMessage>> watchMessages(String threadId, String userId) {
    return Stream.multi((listener) {
      listener.add(List.unmodifiable(_messages[threadId] ?? []));
      final subscription = _controller(
        threadId,
      ).stream.listen(listener.add, onError: listener.addError);
      listener.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> sendMessage(
    String threadId,
    String userId,
    String text, {
    required String clientMessageId,
  }) async {
    if (!_sentIds.add(clientMessageId)) return;
    final active = _threads.firstWhere((thread) => thread.id == threadId);
    if (!active.canSend) throw StateError('This conversation is read-only.');
    final list = _messages.putIfAbsent(threadId, () => []);
    list.add(
      ChatMessage(
        id: clientMessageId,
        threadId: threadId,
        senderId: _me,
        text: text,
        sentAt: DateTime.now(),
        isMine: true,
      ),
    );
    _emit(threadId);

    final thread = _threads.firstWhere((t) => t.id == threadId);
    final reply = _replies[_sent++ % _replies.length];
    _pendingReplies[threadId] = (_pendingReplies[threadId] ?? 0) + 1;
    _typingChanges[threadId]?.add(true);
    _timers.add(
      Timer(replyDelay, () {
        _pendingReplies[threadId] = (_pendingReplies[threadId] ?? 1) - 1;
        _typingChanges[threadId]?.add((_pendingReplies[threadId] ?? 0) > 0);
        final index = _threads.indexWhere((thread) => thread.id == threadId);
        _threads[index] = _threads[index].copyWith(
          unreadCount: _threads[index].unreadCount + 1,
        );
        // Mark everything of mine as read once the worker replies.
        for (var i = 0; i < list.length; i++) {
          if (list[i].isMine) list[i] = list[i].copyWith(isRead: true);
        }
        list.add(
          ChatMessage(
            id: 'r-${DateTime.now().microsecondsSinceEpoch}',
            threadId: threadId,
            senderId: thread.workerId,
            text: reply,
            sentAt: DateTime.now(),
            isMine: false,
          ),
        );
        _emit(threadId);
      }),
    );
  }

  @override
  Future<void> markThreadRead(
    String threadId,
    String userId, {
    required String throughMessageId,
  }) async {
    final list = _messages[threadId];
    if (list == null) return;
    final boundary = list.indexWhere(
      (m) => m.id == throughMessageId && !m.isMine,
    );
    if (boundary < 0) return;
    for (var i = 0; i <= boundary; i++) {
      if (!list[i].isMine) list[i] = list[i].copyWith(isRead: true);
    }
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index >= 0) {
      _threads[index] = _threads[index].copyWith(
        unreadCount: list.where((m) => !m.isMine && !m.isRead).length,
      );
      _emit(threadId);
    }
  }

  @override
  void dispose() {
    _threadChanges.close();
    for (final controller in _typingChanges.values) {
      controller.close();
    }
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}
