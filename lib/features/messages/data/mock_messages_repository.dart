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
      workerId: 'w1',
      workerName: 'Raju K.',
      workerRole: 'Coconut climber',
      isOnline: true,
      unreadCount: 2,
    ),
    const ChatThread(
      id: 't2',
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
  }

  @override
  Future<List<ChatThread>> getThreads(String userId) async {
    await Future.delayed(const Duration(milliseconds: 400));
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
  Future<void> sendMessage(String threadId, String userId, String text) async {
    final list = _messages.putIfAbsent(threadId, () => []);
    list.add(
      ChatMessage(
        id: 'm-${DateTime.now().microsecondsSinceEpoch}',
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
    _timers.add(
      Timer(replyDelay, () {
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
  Future<void> markThreadRead(String threadId, String userId) async {
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index != -1) _threads[index] = _threads[index].copyWith(unreadCount: 0);
  }

  void dispose() {
    for (final timer in _timers) {
      timer.cancel();
    }
    for (final controller in _controllers.values) {
      controller.close();
    }
  }
}
