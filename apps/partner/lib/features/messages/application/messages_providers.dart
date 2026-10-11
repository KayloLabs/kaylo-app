import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../auth/application/partner_session.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../data/mock_messages_repository.dart';
import '../data/supabase_messages_repository.dart';
import '../domain/chat_models.dart';
import '../domain/messages_repository.dart';

final partnerMessagesRepositoryProvider = Provider<PartnerMessagesRepository?>((
  ref,
) {
  ref.watch(
    partnerAuthStateProvider.select(
      (s) => (s.asData?.value.workerId, s.asData?.value.status),
    ),
  );
  final personId = ref.watch(
    workerProfileProvider.select((p) => p.asData?.value?.personId),
  );
  PartnerMessagesRepository? repo;
  if (useMockData) {
    repo = MockPartnerMessagesRepository(
      ref.watch(jobsRepositoryProvider),
      reply: (index) {
        final l = lookupAppLocalizations(ref.read(partnerLocaleProvider));
        return [
          l.chatMockBackGate,
          l.chatMockWaiting,
          l.chatMockCall,
          l.chatMockTenMinutes,
          l.chatMockThanks,
          l.chatMockDog,
        ][index % 6];
      },
    );
  } else if (personId != null) {
    repo = SupabasePartnerMessagesRepository(
      ref.watch(supabaseClientProvider),
      personId: personId,
    );
  }
  ref.onDispose(() => repo?.dispose());
  return repo;
});
final partnerChatThreadsProvider = StreamProvider<List<ChatThread>>(
  (ref) =>
      ref.watch(partnerMessagesRepositoryProvider)?.watchThreads() ??
      const Stream.empty(),
);
final partnerChatThreadProvider = FutureProvider.autoDispose
    .family<ChatThread, String>((ref, id) async {
      final repo = ref.watch(partnerMessagesRepositoryProvider);
      if (repo == null) throw StateError('SESSION_UNAVAILABLE');
      return repo.openThread(id);
    });
final partnerChatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>(
      (ref, id) =>
          ref.watch(partnerMessagesRepositoryProvider)?.watchMessages(id) ??
          const Stream.empty(),
    );
final partnerTypingProvider = StreamProvider.autoDispose.family<bool, String>(
  (ref, id) =>
      ref.watch(partnerMessagesRepositoryProvider)?.watchTyping(id) ??
      const Stream.empty(),
);
final partnerMessageUnreadProvider = Provider<int>(
  (ref) =>
      ref
          .watch(partnerChatThreadsProvider)
          .asData
          ?.value
          .fold<int>(0, (count, thread) => count + thread.unreadCount) ??
      0,
);
final partnerThreadUnreadProvider = Provider.family<int, String>((ref, id) {
  final threads =
      ref.watch(partnerChatThreadsProvider).asData?.value ??
      const <ChatThread>[];
  for (final thread in threads) {
    if (thread.id == id) return thread.unreadCount;
  }
  return 0;
});
