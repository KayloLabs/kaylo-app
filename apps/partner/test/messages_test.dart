import 'support/stream_snapshot.dart';
import 'package:kaylo_partner/features/messages/domain/chat_models.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/messages/application/messages_providers.dart';
import 'package:kaylo_partner/features/messages/data/mock_messages_repository.dart';
import 'package:kaylo_partner/features/messages/presentation/screens/conversation_screen.dart';
import 'package:kaylo_partner/features/jobs/domain/job.dart';
import 'package:kaylo_partner/l10n/generated/app_localizations.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import 'support/round2_jobs.dart';

Widget conversation(
  MockPartnerMessagesRepository repo,
  String id, {
  String locale = 'en',
}) => ProviderScope(
  overrides: [partnerMessagesRepositoryProvider.overrideWithValue(repo)],
  child: MaterialApp(
    theme: AppTheme.lightTheme,
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: PartnerConversationScreen(jobId: id),
  ),
);

class _DelayedMessagesRepository extends MockPartnerMessagesRepository {
  final acknowledgement = Completer<void>();
  _DelayedMessagesRepository(super.jobs) : super(reply: (_) => 'Reply');
  @override
  Future<void> sendMessage(
    String bookingId,
    String text, {
    required String clientMessageId,
  }) async {
    await acknowledgement.future;
    await super.sendMessage(bookingId, text, clientMessageId: clientMessageId);
  }
}

class ReceiptRepository extends MockPartnerMessagesRepository {
  ReceiptRepository(super.jobs) : super(reply: (_) => 'Reply');
  final updates = StreamController<List<ChatMessage>>.broadcast();
  final receipts = <String>[];
  List<ChatMessage> rows = List.generate(
    40,
    (i) => ChatMessage(
      id: 'm$i',
      threadId: 'active',
      senderId: 'customer',
      text: 'Message $i',
      sentAt: DateTime(2026, 10, 11, 10, i),
      isMine: false,
    ),
  );
  @override
  Stream<List<ChatMessage>> watchMessages(String bookingId) async* {
    yield List.of(rows);
    yield* updates.stream;
  }

  @override
  Future<void> markThreadRead(
    String bookingId, {
    required String throughMessageId,
  }) async {
    receipts.add(throughMessageId);
  }

  void receive() {
    final i = rows.length;
    rows = [
      ...rows,
      ChatMessage(
        id: 'm$i',
        threadId: 'active',
        senderId: 'customer',
        text: 'Message $i',
        sentAt: DateTime(2026, 10, 11, 10, i),
        isMine: false,
      ),
    ];
    updates.add(rows);
  }

  @override
  void dispose() {
    updates.close();
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
  testWidgets(
    'older history and background arrivals do not send read receipts',
    (tester) async {
      final jobs = Round2JobsRepository([round2Job('active')]);
      final repo = ReceiptRepository(jobs);
      await tester.pumpWidget(conversation(repo, 'active'));
      await tester.pumpAndSettle();
      expect(repo.receipts.last, 'm39');
      repo.receipts.clear();
      final list = tester
          .widgetList<ListView>(find.byType(ListView))
          .firstWhere((v) => v.controller != null);
      list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
      await tester.pumpAndSettle();
      repo.receive();
      await tester.pumpAndSettle();
      expect(repo.receipts, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      list.controller!.jumpTo(0);
      await tester.pumpAndSettle();
      repo.receive();
      await tester.pumpAndSettle();
      expect(repo.receipts, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(repo.receipts.last, 'm41');
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
      jobs.dispose();
    },
  );
  testWidgets('mounting an inactive conversation never reads messages', (
    tester,
  ) async {
    final jobs = Round2JobsRepository([round2Job('active')]);
    final repo = ReceiptRepository(jobs);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pumpWidget(conversation(repo, 'active'));
    await tester.pumpAndSettle();
    expect(repo.receipts, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repo.receipts.last, 'm39');
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    jobs.dispose();
  });
  testWidgets('eligible jobs appear in the thread list before opening', (
    tester,
  ) async {
    final jobs = Round2JobsRepository([
      round2Job('active'),
      round2Job('completed', stage: JobStage.completed),
      round2Job('requested', stage: JobStage.requested),
    ]);
    final repo = MockPartnerMessagesRepository(jobs, reply: (_) => 'Reply');
    await tester.pump();
    final threads = await streamSnapshot(tester, repo.watchThreads());
    expect(threads.map((t) => t.id).toSet(), {'active', 'completed'});
    expect(threads.singleWhere((t) => t.id == 'completed').canSend, isFalse);
    repo.dispose();
    jobs.dispose();
  });
  testWidgets('pending send locks input and cannot erase a newer draft', (
    tester,
  ) async {
    final jobs = Round2JobsRepository([round2Job('active')]);
    final repo = _DelayedMessagesRepository(jobs);
    await tester.pumpWidget(conversation(repo, 'active'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('partner-chat-composer')),
      'First message',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('partner-chat-send')));
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const Key('partner-chat-composer')),
    );
    expect(field.readOnly, isTrue);
    // A restored draft or platform autofill can change a controller while an acknowledgement is pending.
    field.controller!.text = 'Newer draft';
    repo.acknowledgement.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(field.controller!.text, 'Newer draft');
    expect(
      (await streamSnapshot(tester, repo.watchMessages('active'))).single.text,
      'First message',
    );
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    jobs.dispose();
  });
  testWidgets(
    'conversation sends, shows typing, receives reply and read receipt',
    (tester) async {
      final jobs = Round2JobsRepository([round2Job('active')]);
      final repo = MockPartnerMessagesRepository(
        jobs,
        reply: (_) => 'Please come to the back gate.',
      );
      await tester.pumpWidget(conversation(repo, 'active'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('partner-chat-composer')),
        'On my way to your home',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('partner-chat-send')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('On my way to your home'), findsOneWidget);
      expect(find.byIcon(Icons.done_rounded), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsNothing);
      expect(find.text('Customer is typing…'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Please come to the back gate.'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('On my way to your home')).dy,
        lessThan(
          tester.getTopLeft(find.text('Please come to the back gate.')).dy,
        ),
      );
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
      jobs.dispose();
    },
  );
  testWidgets('opening a thread clears the customer reply unread count', (
    tester,
  ) async {
    final jobs = Round2JobsRepository([round2Job('active')]);
    final repo = MockPartnerMessagesRepository(
      jobs,
      reply: (_) => 'Okay, waiting.',
    );
    await repo.sendMessage('active', 'Hello', clientMessageId: 'one');
    await tester.pump(const Duration(seconds: 4));
    expect(
      (await streamSnapshot(tester, repo.watchThreads())).single.unreadCount,
      1,
    );
    await tester.pumpWidget(conversation(repo, 'active'));
    await tester.pumpAndSettle();
    expect(
      (await streamSnapshot(tester, repo.watchThreads())).single.unreadCount,
      0,
    );
    final readMessages = await streamSnapshot(
      tester,
      repo.watchMessages('active'),
    );
    expect(readMessages.where((m) => !m.isMine).every((m) => m.isRead), isTrue);
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    jobs.dispose();
  });
  testWidgets('completed conversation is readable without a composer', (
    tester,
  ) async {
    final jobs = Round2JobsRepository([
      round2Job('complete', stage: JobStage.completed),
    ]);
    final repo = MockPartnerMessagesRepository(jobs, reply: (_) => 'Reply');
    await tester.pumpWidget(conversation(repo, 'complete'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('partner-chat-composer')), findsNothing);
    expect(
      find.text('This booking has ended. You can still read its conversation.'),
      findsOneWidget,
    );
    await expectLater(
      repo.sendMessage('complete', 'Hello', clientMessageId: 'one'),
      throwsStateError,
    );
    await tester.pumpWidget(const SizedBox());
    repo.dispose();
    jobs.dispose();
  });
  testWidgets('retry id is idempotent and completion cancels queued reply', (
    tester,
  ) async {
    final jobs = Round2JobsRepository([round2Job('active')]);
    final repo = MockPartnerMessagesRepository(jobs, reply: (_) => 'Reply');
    await repo.sendMessage('active', 'Hello', clientMessageId: 'same-id');
    await repo.sendMessage('active', 'Hello', clientMessageId: 'same-id');
    expect(
      (await streamSnapshot(tester, repo.watchMessages('active'))).length,
      1,
    );
    jobs.setStage('active', JobStage.completed);
    await tester.pump(const Duration(seconds: 5));
    expect(
      (await streamSnapshot(tester, repo.watchMessages('active'))).length,
      1,
    );
    expect(
      (await streamSnapshot(tester, repo.watchThreads())).single.canSend,
      isFalse,
    );
    repo.dispose();
    jobs.dispose();
  });
  testWidgets('requested jobs cannot open a conversation', (tester) async {
    final jobs = Round2JobsRepository([
      round2Job('request', stage: JobStage.requested),
    ]);
    final repo = MockPartnerMessagesRepository(jobs, reply: (_) => 'Reply');
    await expectLater(repo.openThread('request'), throwsStateError);
    repo.dispose();
    jobs.dispose();
  });
  for (final locale in ['hi', 'ml', 'ta']) {
    testWidgets('conversation fits a small phone in $locale', (tester) async {
      tester.view.physicalSize = const Size(360, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final jobs = Round2JobsRepository([round2Job('active')]);
      final repo = MockPartnerMessagesRepository(jobs, reply: (_) => 'Reply');
      await tester.pumpWidget(conversation(repo, 'active', locale: locale));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      repo.dispose();
      jobs.dispose();
    });
  }
}
