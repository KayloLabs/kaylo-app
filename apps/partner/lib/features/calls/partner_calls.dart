import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import '../auth/application/partner_session.dart';
import '../../l10n/generated/app_localizations.dart';

final callPersonProvider = FutureProvider<String?>((ref) async {
  if (useMockData) return null;
  final session = ref.watch(partnerAuthStateProvider).asData?.value;
  if (session?.canWork != true) return null;
  return await ref.watch(supabaseClientProvider).rpc('current_person_id')
      as String?;
});

final partnerIncomingCallsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final pid = await ref.watch(callPersonProvider.future);
      if (pid == null) return [];
      final timer = Timer(const Duration(seconds: 5), ref.invalidateSelf);
      ref.onDispose(timer.cancel);
      if (WidgetsBinding.instance.lifecycleState != null &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        return [];
      }
      return await ref
          .watch(supabaseClientProvider)
          .from('care_call_members')
          .select(
            'call_id,care_calls!inner(id,booking_id,created_at,ended_at,expires_at)',
          )
          .eq('person_id', pid)
          .eq('status', 'invited')
          .not('care_calls.booking_id', 'is', null)
          .isFilter('care_calls.ended_at', null)
          .gt('care_calls.expires_at', DateTime.now().toUtc().toIso8601String())
          .gt(
            'care_calls.created_at',
            DateTime.now()
                .subtract(const Duration(minutes: 2))
                .toUtc()
                .toIso8601String(),
          );
    });

Future<void> startPartnerBookingCall(
  BuildContext context,
  WidgetRef ref,
  String bookingId,
) async {
  try {
    final id =
        await ref
                .read(supabaseClientProvider)
                .rpc('start_booking_call', params: {'p_booking_id': bookingId})
            as String;
    if (context.mounted) await context.push('/booking-call/$id');
  } catch (_) {
    if (context.mounted) {
      KayloSnackbar.showError(
        context,
        AppLocalizations.of(context)!.bookingCallFailed,
      );
    }
  }
}

class PartnerCallOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouter router;
  const PartnerCallOverlay({
    super.key,
    required this.child,
    required this.router,
  });
  @override
  ConsumerState<PartnerCallOverlay> createState() => _PartnerCallOverlayState();
}

class _PartnerCallOverlayState extends ConsumerState<PartnerCallOverlay> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final calls = ref.watch(partnerIncomingCallsProvider).asData?.value ?? [];
    final l = AppLocalizations.of(context)!;
    return Stack(
      children: [
        widget.child,
        if (calls.isNotEmpty && !_busy)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.call),
                  title: Text(l.bookingCallIncoming),
                  subtitle: Text(l.bookingCallIncomingBody),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: l.decline,
                        icon: const Icon(Icons.call_end),
                        onPressed: () async {
                          setState(() => _busy = true);
                          try {
                            await ref
                                .read(supabaseClientProvider)
                                .rpc(
                                  'respond_care_call',
                                  params: {
                                    'p_call_id': calls.first['call_id'],
                                    'p_action': 'declined',
                                  },
                                );
                          } catch (_) {
                            // Keep the invitation visible for a retry.
                          } finally {
                            ref.invalidate(partnerIncomingCallsProvider);
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                      ),
                      IconButton(
                        tooltip: l.bookingCallTitle,
                        icon: const Icon(Icons.call),
                        onPressed: () async {
                          setState(() => _busy = true);
                          try {
                            await widget.router.push(
                              '/booking-call/${calls.first['call_id']}',
                            );
                          } finally {
                            ref.invalidate(partnerIncomingCallsProvider);
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
