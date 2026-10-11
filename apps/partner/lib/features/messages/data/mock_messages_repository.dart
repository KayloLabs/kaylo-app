import 'dart:async';
import '../../jobs/domain/job.dart';
import '../../jobs/domain/jobs_repository.dart';
import '../domain/chat_models.dart';
import '../domain/messages_repository.dart';

class MockPartnerMessagesRepository implements PartnerMessagesRepository {
  final JobsRepository jobs;
  final String Function(int) reply;
  final Duration replyDelay;
  final _changes = StreamController<void>.broadcast();
  final Map<String, ChatThread> _threads = {};
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, List<Timer>> _timers = {};
  final Set<String> _typing = {};
  late final StreamSubscription<List<Job>> _jobsSubscription;
  bool _disposed = false;
  int _replyIndex = 0;
  MockPartnerMessagesRepository(
    this.jobs, {
    required this.reply,
    this.replyDelay = const Duration(milliseconds: 2800),
  }) {
    _jobsSubscription = jobs.watchJobs().listen((rows) {
      for (final row in rows) {
        if (row.isActive || row.isCompleted) {
          _threads.putIfAbsent(
            row.id,
            () => ChatThread(
              id: row.id,
              roomId: row.id,
              customerName: row.customerName,
              serviceName: row.serviceName,
              canSend: row.isActive,
            ),
          );
          _messages.putIfAbsent(row.id, () => []);
        }
        final thread = _threads[row.id];
        if (thread != null) {
          _threads[row.id] = thread.copyWith(canSend: row.isActive);
          if (!row.isActive) {
            for (final timer in _timers.remove(row.id) ?? <Timer>[]) {
              timer.cancel();
            }
            _typing.remove(row.id);
          }
        }
      }
      _emit();
    });
  }
  void _emit() {
    if (!_disposed) _changes.add(null);
  }

  Stream<T> _watch<T>(T Function() read) => Stream.multi((sink) {
    final sub = _changes.stream.listen(
      (_) => sink.add(read()),
      onError: sink.addError,
      onDone: sink.close,
    );
    sink.add(read());
    sink.onCancel = sub.cancel;
  });
  @override
  Stream<List<ChatThread>> watchThreads() => _watch(
    () => _threads.values.toList()
      ..sort(
        (a, b) => (b.lastMessageAt ?? DateTime(0)).compareTo(
          a.lastMessageAt ?? DateTime(0),
        ),
      ),
  );
  @override
  Future<ChatThread> openThread(String bookingId) async {
    final job = await jobs.getJobById(bookingId);
    if (_disposed ||
        job == null ||
        job.isRequested ||
        (job.isCancelled && !_threads.containsKey(bookingId))) {
      throw StateError('CHAT_UNAVAILABLE');
    }
    final thread = _threads.putIfAbsent(
      bookingId,
      () => ChatThread(
        id: job.id,
        roomId: job.id,
        customerName: job.customerName,
        serviceName: job.serviceName,
        canSend: job.isActive,
      ),
    );
    _messages.putIfAbsent(bookingId, () => []);
    _emit();
    return thread;
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String bookingId) async* {
    await openThread(bookingId);
    yield* _watch(
      () => List.unmodifiable(_messages[bookingId] ?? <ChatMessage>[]),
    );
  }

  @override
  Future<void> sendMessage(
    String bookingId,
    String text, {
    required String clientMessageId,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || trimmed.length > 4000) {
      throw ArgumentError('INVALID_MESSAGE');
    }
    await openThread(bookingId);
    final job = await jobs.getJobById(bookingId);
    if (_disposed || job?.isActive != true) throw StateError('CHAT_READ_ONLY');
    final items = _messages[bookingId]!;
    if (items.any((m) => m.id == clientMessageId)) return;
    final now = DateTime.now();
    items.add(
      ChatMessage(
        id: clientMessageId,
        threadId: bookingId,
        senderId: 'partner',
        text: trimmed,
        sentAt: now,
        isMine: true,
      ),
    );
    _threads[bookingId] = _threads[bookingId]!.copyWith(
      lastMessage: trimmed,
      lastMessageAt: now,
    );
    _emit();
    final timers = _timers.putIfAbsent(bookingId, () => []);
    timers.add(
      Timer(const Duration(milliseconds: 450), () {
        if (_disposed || _threads[bookingId]?.canSend != true) return;
        _typing.add(bookingId);
        _emit();
      }),
    );
    timers.add(
      Timer(replyDelay, () async {
        final latest = await jobs.getJobById(bookingId);
        if (_disposed || latest?.isActive != true) {
          _typing.remove(bookingId);
          _emit();
          return;
        }
        for (var i = 0; i < items.length; i++) {
          if (items[i].isMine) items[i] = items[i].copyWith(isRead: true);
        }
        final text = reply(_replyIndex++), now = DateTime.now();
        items.add(
          ChatMessage(
            id: 'reply-$clientMessageId',
            threadId: bookingId,
            senderId: 'customer',
            text: text,
            sentAt: now,
            isMine: false,
          ),
        );
        final thread = _threads[bookingId]!;
        _threads[bookingId] = thread.copyWith(
          lastMessage: text,
          lastMessageAt: now,
          unreadCount: thread.unreadCount + 1,
        );
        _typing.remove(bookingId);
        _timers[bookingId]?.removeWhere((timer) => !timer.isActive);
        _emit();
      }),
    );
  }

  @override
  Future<void> markThreadRead(
    String bookingId, {
    required String throughMessageId,
  }) async {
    final thread = _threads[bookingId];
    final messages = _messages[bookingId];
    if (thread == null || messages == null) return;
    final boundary = messages.indexWhere(
      (m) => m.id == throughMessageId && !m.isMine,
    );
    if (boundary < 0) return;
    for (var i = 0; i <= boundary; i++) {
      if (!messages[i].isMine) messages[i] = messages[i].copyWith(isRead: true);
    }
    _threads[bookingId] = thread.copyWith(
      unreadCount: messages.where((m) => !m.isMine && !m.isRead).length,
    );
    _emit();
  }

  @override
  Stream<bool> watchTyping(String bookingId) =>
      _watch(() => _typing.contains(bookingId));
  @override
  Future<void> setTyping(String bookingId, bool typing) async {}
  @override
  void dispose() {
    _disposed = true;
    _jobsSubscription.cancel();
    for (final timers in _timers.values) {
      for (final timer in timers) {
        timer.cancel();
      }
    }
    _timers.clear();
    _changes.close();
  }
}
