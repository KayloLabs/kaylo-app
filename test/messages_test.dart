import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo/core/router/routes.dart';
import 'package:kaylo/features/auth/application/current_user_provider.dart';
import 'package:kaylo/features/messages/application/messages_providers.dart';
import 'package:kaylo/features/messages/data/mock_messages_repository.dart';
import 'package:kaylo/features/messages/presentation/screens/conversation_screen.dart';
import 'package:kaylo/features/messages/presentation/screens/messages_screen.dart';
import 'package:kaylo/l10n/generated/app_localizations.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Widget app({required String initialLocation}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.messages,
        builder: (_, _) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/chat/:threadId',
        builder: (_, state) => ConversationScreen(
          threadId: state.pathParameters['threadId']!,
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      currentUserIdProvider.overrideWithValue('mock_uid_1'),
      messagesRepositoryProvider.overrideWith((ref) {
        final repo = MockMessagesRepository(
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

void main() {
  testWidgets('thread list shows workers and opens a conversation',
      (tester) async {
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

  testWidgets('sending a message shows it and the worker replies',
      (tester) async {
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
}
