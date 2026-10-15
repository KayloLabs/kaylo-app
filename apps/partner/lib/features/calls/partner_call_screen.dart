import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_ui/widgets/kaylo_voice_call_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'partner_calls.dart';

class PartnerCallScreen extends ConsumerWidget {
  final String callId;
  const PartnerCallScreen({super.key, required this.callId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return ref
        .watch(callPersonProvider)
        .when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (_, _) =>
              Scaffold(body: Center(child: Text(l10n.bookingCallFailed))),
          data: (pid) => pid == null
              ? Scaffold(body: Center(child: Text(l10n.bookingCallFailed)))
              : KayloVoiceCallScreen(
                  callId: callId,
                  personId: pid,
                  client: ref.read(supabaseClientProvider),
                  onClosed: () => ref.invalidate(partnerIncomingCallsProvider),
                  labels: {
                    'callAudioOutputFailed': l10n.callAudioOutputFailed,
                    'callConnecting': l10n.callConnecting,
                    'callCouldNotConnect': l10n.callCouldNotConnect,
                    'callDeclined': l10n.callDeclined,
                    'callEndForEveryone': l10n.callEndForEveryone,
                    'callEnded': l10n.callEnded,
                    'callErrorJoin': l10n.callErrorJoin,
                    'callErrorMicrophone': l10n.callErrorMicrophone,
                    'callErrorRoom': l10n.callErrorRoom,
                    'callErrorSettings': l10n.callErrorSettings,
                    'callInterrupted': l10n.callInterrupted,
                    'callInvitedWaiting': l10n.callInvitedWaiting,
                    'callKeepOpen': l10n.callKeepOpen,
                    'callLeave': l10n.callLeave,
                    'callLeft': l10n.callLeft,
                    'callPeerConnected': l10n.callPeerConnected,
                    'callPeerConnecting': l10n.callPeerConnecting,
                    'callPeerFailed': l10n.callPeerFailed,
                    'callPeerReconnecting': l10n.callPeerReconnecting,
                    'callTitle': l10n.callTitle,
                    'callYou': l10n.callYou,
                    'callYouMuted': l10n.callYouMuted,
                    'callYourCircle': l10n.callYourCircle,
                    'close': l10n.close,
                    'mute': l10n.mute,
                    'retryCall': l10n.retryCall,
                    'speaker': l10n.speaker,
                    'unmute': l10n.unmute,
                    'bookingCallTitle': l10n.bookingCallTitle,
                    'bookingCallConnected': l10n.bookingCallConnected,
                  },
                ),
        );
  }
}
