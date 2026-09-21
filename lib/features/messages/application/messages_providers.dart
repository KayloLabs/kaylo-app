import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/supabase_providers.dart';
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
  return SupabaseMessagesRepository(ref.watch(supabaseClientProvider));
});

final chatThreadsProvider =
    FutureProvider.autoDispose<List<ChatThread>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(messagesRepositoryProvider).getThreads(userId);
});

final chatThreadProvider =
    FutureProvider.autoDispose.family<ChatThread, String>((ref, id) async {
  final threads = await ref.watch(chatThreadsProvider.future);
  return threads.firstWhere(
    (t) => t.id == id,
    orElse: () =>
        throw ServerFailure('Conversation not found', code: 'not-found'),
  );
});

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, threadId) {
  final userId = ref.watch(currentUserIdProvider) ?? '';
  return ref.watch(messagesRepositoryProvider).watchMessages(threadId, userId);
});
