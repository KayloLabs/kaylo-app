import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/messages/application/messages_providers.dart';
import 'package:kaylo/features/messages/data/mock_messages_repository.dart';
import 'package:kaylo/features/messages/domain/messages_repository.dart';
import 'package:kaylo/features/messages/domain/chat_models.dart';
import 'package:kaylo/features/messages/presentation/screens/conversation_screen.dart';
import 'package:kaylo/features/messages/presentation/screens/messages_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Widget app({required String initialLocation, MessagesRepository? repository}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: Routes.messages, builder: (_, _) => const MessagesScreen()),
      GoRoute(
        path: '/chat/:threadId',
        builder: (_, state) =>
            ConversationScreen(threadId: state.pathParameters['threadId']!),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('mock_uid_1'),
      messagesRepositoryProvider.overrideWith((ref) {
        final repo =
            repository ??
            MockMessagesRepository(
              replyDelay: const Duration(milliseconds: 200),
            );
        ref.onDispose(repo.dispose);
        return repo;
      }),
    ],
    child: MaterialApp.router(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

class ControlledMessagesRepository extends MockMessagesRepository {
  ControlledMessagesRepository({super.replyDelay = const Duration(seconds: 2)});
  final sentIds = <String>[];
  final sentTexts = <String>[];
  final typingSignals = <bool>[];
  int readCalls = 0;
  bool failNextSend = false;
  Completer<void>? holdSend;
  final _threadUpdates = StreamController<List<ChatThread>>.broadcast();
  bool writable = true;

  @override
  Future<void> sendMessage(
    String threadId,
    String userId,
    String text, {
    required String clientMessageId,
  }) async {
    sentIds.add(clientMessageId);
    sentTexts.add(text);
    if (failNextSend) {
      failNextSend = false;
      throw StateError('offline');
    }
    await holdSend?.future;
    await super.sendMessage(
      threadId,
      userId,
      text,
      clientMessageId: clientMessageId,
    );
  }

  @override
  Future<void> markThreadRead(
    String threadId,
    String userId, {
    required String throughMessageId,
  }) async {
    readCalls++;
    await super.markThreadRead(
      threadId,
      userId,
      throughMessageId: throughMessageId,
    );
  }

  @override
  Future<void> setTyping(String threadId, String userId, bool typing) async {
    typingSignals.add(typing);
  }

  @override
  Future<List<ChatThread>> getThreads(String userId) async =>
      (await super.getThreads(userId))
          .map(
            (thread) => ChatThread(
              id: thread.id,
              bookingId: thread.bookingId,
              workerId: thread.workerId,
              workerName: thread.workerName,
              workerRole: thread.workerRole,
              isOnline: thread.isOnline,
              unreadCount: thread.unreadCount,
              lastMessage: thread.lastMessage,
              lastMessageAt: thread.lastMessageAt,
              canSend: writable,
            ),
          )
          .toList();

  @override
  Stream<List<ChatThread>> watchThreads(String userId) => Stream.multi((sink) {
    final initial = super
        .watchThreads(userId)
        .listen(sink.add, onError: sink.addError);
    final updates = _threadUpdates.stream.listen(sink.add);
    sink.onCancel = () async {
      await initial.cancel();
      await updates.cancel();
    };
  });

  Future<void> setWritable(bool value) async {
    writable = value;
    _threadUpdates.add(await getThreads('mock_uid_1'));
  }

  @override
  void dispose() {
    _threadUpdates.close();
    super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(
    () => WidgetsBinding.instance.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    ),
  );
  testWidgets('thread list shows workers and opens a conversation', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialLocation: Routes.messages));
    await settle(tester);

    expect(find.text('Raju K.'), findsOneWidget);
    expect(find.text('Manoj P.'), findsOneWidget);
    expect(find.text('2'), findsOneWidget, reason: 'unread badge');

    await tester.tap(find.text('Raju K.'));
    await settle(tester);

    expect(find.textContaining('10 coconut trees'), findsOneWidget);
    expect(find.text('Online'), findsOneWidget);
  });

  testWidgets('sending a message shows it and the worker replies', (
    tester,
  ) async {
    await tester.pumpWidget(app(initialLocation: Routes.chat('t1')));
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'Please come by 8 AM');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();

    expect(find.text('Please come by 8 AM'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('checklist'), findsOneWidget);
  });

  testWidgets(
    'failed send preserves draft and retries with the same message ID',
    (tester) async {
      final repo = ControlledMessagesRepository()..failNextSend = true;
      await tester.pumpWidget(
        app(initialLocation: Routes.chat('t1'), repository: repo),
      );
      await settle(tester);
      await tester.enterText(
        find.byType(TextField),
        'Please use the side gate',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Please use the side gate',
      );
      expect(find.textContaining('Tap send to retry'), findsOneWidget);
      expect(repo.sentIds, hasLength(1));
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(repo.sentIds, hasLength(2));
      expect(repo.sentIds[1], repo.sentIds[0]);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(find.text('Please use the side gate'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'repeated send taps cannot submit another message while sending',
    (tester) async {
      final repo = ControlledMessagesRepository()..holdSend = Completer<void>();
      await tester.pumpWidget(
        app(initialLocation: Routes.chat('t1'), repository: repo),
      );
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'See you at eight');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      // Tap again before the disabled state has even painted.
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      expect(repo.sentIds, hasLength(1));
      expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
      repo.holdSend!.complete();
      await tester.pump();
      expect(find.text('See you at eight'), findsOneWidget);
      expect(repo.sentIds, hasLength(1));
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('typing appears during a reply and disappears when it arrives', (
    tester,
  ) async {
    final repo = ControlledMessagesRepository(
      replyDelay: const Duration(seconds: 2),
    );
    await tester.pumpWidget(
      app(initialLocation: Routes.chat('t1'), repository: repo),
    );
    await settle(tester);
    expect(find.text('typing...'), findsNothing);
    await tester.enterText(find.byType(TextField), 'Please bring your tools');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('typing...'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('typing...'), findsNothing);
    expect(find.textContaining('checklist'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'an incoming reply is marked read while the conversation is open',
    (tester) async {
      final repo = ControlledMessagesRepository(
        replyDelay: const Duration(milliseconds: 200),
      );
      await tester.pumpWidget(
        app(initialLocation: Routes.chat('t1'), repository: repo),
      );
      await settle(tester);
      final initialReads = repo.readCalls;
      expect(
        (await repo.getThreads(
          'mock_uid_1',
        )).firstWhere((t) => t.id == 't1').unreadCount,
        0,
      );
      await tester.enterText(find.byType(TextField), 'I will be home');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(repo.readCalls, greaterThan(initialReads));
      expect(
        (await repo.getThreads(
          'mock_uid_1',
        )).firstWhere((t) => t.id == 't1').unreadCount,
        0,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('background messages stay unread until the app resumes', (
    tester,
  ) async {
    final repo = ControlledMessagesRepository(
      replyDelay: const Duration(milliseconds: 200),
    );
    await tester.pumpWidget(
      app(initialLocation: Routes.chat('t1'), repository: repo),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'I will meet you outside');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    addTearDown(() {
      if (tester.binding.lifecycleState == AppLifecycleState.paused) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      }
      if (tester.binding.lifecycleState == AppLifecycleState.hidden) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(repo.typingSignals.last, isFalse);
    expect(
      (await repo.getThreads(
        'mock_uid_1',
      )).firstWhere((t) => t.id == 't1').unreadCount,
      1,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(
      (await repo.getThreads(
        'mock_uid_1',
      )).firstWhere((t) => t.id == 't1').unreadCount,
      0,
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'thread updates remove the composer when a booking becomes read-only',
    (tester) async {
      final repo = ControlledMessagesRepository();
      await tester.pumpWidget(
        app(initialLocation: Routes.chat('t1'), repository: repo),
      );
      await settle(tester);
      expect(find.byType(TextField), findsOneWidget);
      await repo.setWritable(false);
      await tester.pump();
      await tester.pump();
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('This booking has ended'), findsOneWidget);
      expect(repo.sentIds, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
