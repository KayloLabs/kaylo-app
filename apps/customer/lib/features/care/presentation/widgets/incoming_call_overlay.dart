import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../../application/care_calls.dart';
import '../../../../l10n/generated/app_localizations.dart';

class IncomingCallOverlay extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouter router;
  const IncomingCallOverlay({
    super.key,
    required this.child,
    required this.router,
  });
  @override
  ConsumerState<IncomingCallOverlay> createState() =>
      _IncomingCallOverlayState();
}

class _IncomingCallOverlayState extends ConsumerState<IncomingCallOverlay> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final incoming = ref.watch(incomingCareCallsProvider).asData?.value ?? [];
    final l = AppLocalizations.of(context)!;
    final bookingCall =
        incoming.isNotEmpty &&
        incoming.first['care_calls']['booking_id'] != null;
    return Stack(
      children: [
        widget.child,
        if (incoming.isNotEmpty && !_busy)
          Positioned(
            top: 0,
            left: 12,
            right: 12,
            child: SafeArea(
              child: Card(
                child: ListTile(
                  leading: Icon(bookingCall ? Icons.call : Icons.emergency),
                  title: Text(
                    bookingCall ? l.bookingCallIncoming : l.incomingSosTitle,
                  ),
                  subtitle: Text(
                    bookingCall
                        ? l.bookingCallIncomingBody
                        : l.incomingSosSubtitle,
                  ),
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
                                    'p_call_id': incoming.first['call_id'],
                                    'p_action': 'declined',
                                  },
                                );
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l.bookingCallFailed)),
                              );
                            }
                          } finally {
                            ref.invalidate(incomingCareCallsProvider);
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                      ),
                      IconButton(
                        tooltip: l.joinCall,
                        icon: const Icon(Icons.call),
                        onPressed: () async {
                          setState(() => _busy = true);
                          try {
                            await widget.router.push(
                              '/booking-call/${incoming.first['call_id']}',
                            );
                          } finally {
                            ref.invalidate(incomingCareCallsProvider);
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
