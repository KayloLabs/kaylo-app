import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../auth/application/current_user_provider.dart';
import '../data/mock_messages_repository.dart';
import '../data/supabase_messages_repository.dart';
import '../domain/chat_models.dart';
import '../domain/messages_repository.dart';

final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  if (useMockData) {
    final repo = MockMessagesRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  ref.watch(currentUserIdProvider);
  final repo = SupabaseMessagesRepository(ref.watch(supabaseClientProvider));
  ref.onDispose(repo.dispose);
  return repo;
});

final chatThreadsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(const []);
  return ref.watch(messagesRepositoryProvider).watchThreads(userId);
});

final chatThreadProvider = Provider.autoDispose
    .family<AsyncValue<ChatThread>, String>((ref, id) {
      return ref
          .watch(chatThreadsProvider)
          .whenData(
            (threads) => threads.firstWhere(
              (thread) => thread.id == id,
              orElse: () => throw ServerFailure(
                'Conversation not found',
                code: 'not-found',
              ),
            ),
          );
    });

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) return Stream.value(const []);
      return ref
          .watch(messagesRepositoryProvider)
          .watchMessages(threadId, userId);
    });

final chatTypingProvider = StreamProvider.autoDispose.family<bool, String>((
  ref,
  threadId,
) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(false);
  return ref.watch(messagesRepositoryProvider).watchTyping(threadId, userId);
});
