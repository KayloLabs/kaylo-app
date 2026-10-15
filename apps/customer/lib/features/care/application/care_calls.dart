import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../auth/application/current_user_provider.dart';

final careConnectionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      if (useMockData || ref.watch(currentUserIdProvider) == null) return [];
      return await ref
          .watch(supabaseClientProvider)
          .from('care_connections')
          .select();
    });
final incomingCareCallsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      if (useMockData || ref.watch(currentUserIdProvider) == null) return [];
      final timer = Timer(const Duration(seconds: 5), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      if (WidgetsBinding.instance.lifecycleState != null &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return [];
      }
      final client = ref.watch(supabaseClientProvider);
      return await client
          .from('care_call_members')
          .select(
            'call_id,care_calls!inner(id,booking_id,created_at,ended_at,expires_at)',
          )
          .eq('person_id', ref.watch(currentUserIdProvider)!)
          .eq('status', 'invited')
          .isFilter('care_calls.ended_at', null)
          .gt(
            'care_calls.created_at',
            DateTime.now()
                .subtract(const Duration(minutes: 2))
                .toUtc()
                .toIso8601String(),
          );
    });
