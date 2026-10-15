import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/application/partner_session.dart';

/// One identity-scoped subscription shared by the profile and reviews screens.
/// A periodic refresh also recovers changes missed while disconnected.
final partnerReviewChangesProvider = StreamProvider<int>((ref) {
  if (useMockData) return const Stream.empty();
  final workerId = ref.watch(
    partnerAuthStateProvider.select((s) => s.asData?.value.workerId),
  );
  if (workerId == null) return const Stream.empty();
  final client = ref.watch(supabaseClientProvider);
  final changes = StreamController<int>();
  RealtimeChannel? channel;
  var disposed = false;
  var revision = 0;
  void changed() {
    if (!disposed) changes.add(++revision);
  }

  final timer = Timer.periodic(const Duration(seconds: 30), (_) => changed());
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
    unawaited(changes.close());
    final current = channel;
    if (current != null) {
      unawaited(
        client
            .removeChannel(current)
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
  });

  Future<void> subscribe() async {
    try {
      final personId = await client.rpc('current_person_id') as String?;
      if (disposed || personId == null) return;
      channel =
          client.channel(
              'kaylo-chat:$personId:partner-reviews:${identityHashCode(changes)}',
              opts: const RealtimeChannelConfig(private: true),
            )
            ..onPostgresChanges(
                  event: PostgresChangeEvent.all,
                  schema: 'public',
                  table: 'reviews',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'worker_id',
                    value: workerId,
                  ),
                  callback: (_) => changed(),
                )
                .onPostgresChanges(
                  event: PostgresChangeEvent.update,
                  schema: 'public',
                  table: 'workers',
                  filter: PostgresChangeFilter(
                    type: PostgresChangeFilterType.eq,
                    column: 'worker_id',
                    value: workerId,
                  ),
                  callback: (_) => changed(),
                )
                .subscribe((status, error) {
                  // Re-read after subscribing/reconnecting to close the initial read gap.
                  if (status == RealtimeSubscribeStatus.subscribed) changed();
                });
    } catch (_) {
      // The authenticated RPC reads continue through the fallback timer.
    }
  }

  unawaited(subscribe());
  return changes.stream;
});
