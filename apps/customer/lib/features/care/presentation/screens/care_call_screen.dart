import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/application/current_user_provider.dart';
import '../../application/care_calls.dart';
import '../../../../l10n/generated/app_localizations.dart';

class CareCallScreen extends ConsumerStatefulWidget {
  final String callId;
  const CareCallScreen({super.key, required this.callId});
  @override
  ConsumerState<CareCallScreen> createState() => _CareCallScreenState();
}

class _CareCallScreenState extends ConsumerState<CareCallScreen> {
  AppLocalizations get _l10n => AppLocalizations.of(context)!;
  late final SupabaseClient _client = ref.read(supabaseClientProvider);
  late final String _pid = ref.read(currentUserIdProvider)!;
  final Map<String, RTCPeerConnection> _peers = {};
  final Map<String, List<RTCIceCandidate>> _candidates = {};
  final Set<String> _described = {};
  final Map<String, String> _states = {};
  final Map<String, RTCVideoRenderer> _audio = {};
  List<Map<String, dynamic>> _members = [];
  MediaStream? _local;
  Timer? _timer;
  bool _polling = false,
      _muted = false,
      _speaker = true,
      _ended = false,
      _ready = false;
  bool _starting = false;
  String? _owner;
  String? _error;
  int _lastSignal = 0;
  List<dynamic> _iceServers = [];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    if (_starting || _ended) return;
    setState(() {
      _starting = true;
      _error = null;
      _ready = false;
    });
    var stage = 'room';
    try {
      final room = await _client
          .from('care_calls')
          .select()
          .eq('id', widget.callId)
          .single();
      if (_ended) return;
      if (room['ended_at'] != null ||
          DateTime.parse(
            room['expires_at'] as String,
          ).isBefore(DateTime.now())) {
        throw StateError('Call ended');
      }
      _owner = room['owner_id'] as String;
      stage = 'settings';
      final config = await _client.functions.invoke(
        'care-call',
        body: {'action': 'config'},
      );
      _iceServers = (config.data['ice_servers'] as List<dynamic>);
      if (_ended) return;
      stage = 'microphone';
      _local = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      if (_ended) {
        await _release();
        return;
      }
      // Chrome selects audio output itself; this helper calls a native plugin.
      if (!kIsWeb) {
        try {
          await Helper.setSpeakerphoneOn(true);
        } catch (_) {
          // Keep the device's default output if speaker routing is unavailable.
          _speaker = false;
        }
      }
      if (_ended) return;
      stage = 'join';
      await _client.rpc(
        'respond_care_call',
        params: {'p_call_id': widget.callId, 'p_action': 'joined'},
      );
      if (_ended) return;
      setState(() => _ready = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _poll());
      await _poll();
    } catch (error) {
      debugPrint('Kaylo call setup failed at $stage (${error.runtimeType}).');
      await _release();
      if (mounted && !_ended) {
        setState(() {
          _ready = false;
          _error = switch (stage) {
            'room' => _l10n.callErrorRoom,
            'settings' => _l10n.callErrorSettings,
            'microphone' => _l10n.callErrorMicrophone,
            _ => _l10n.callErrorJoin,
          };
        });
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _send(String target, Map<String, dynamic> payload) async {
    if (_ended) return;
    await _client.from('care_call_signals').insert({
      'call_id': widget.callId,
      'sender_id': _pid,
      'target_id': target,
      'payload': payload,
    });
  }

  Future<RTCPeerConnection> _peer(String id) async {
    if (_peers[id] != null) return _peers[id]!;
    final pc = await createPeerConnection({
      'iceServers': _iceServers,
      'sdpSemantics': 'unified-plan',
    });
    if (_ended) {
      await pc.close();
      throw StateError('Call ended');
    }
    _peers[id] = pc;
    for (final track in _local!.getTracks()) {
      await pc.addTrack(track, _local!);
    }
    pc.onIceCandidate = (c) {
      if (c.candidate != null && !_ended) {
        unawaited(
          _send(id, {
            'type': 'candidate',
            'candidate': c.toMap(),
          }).catchError((Object _) {}),
        );
      }
    };
    pc.onConnectionState = (state) {
      if (!mounted || _ended) return;
      setState(
        () => _states[id] = switch (state) {
          RTCPeerConnectionState.RTCPeerConnectionStateConnected =>
            _l10n.callPeerConnected,
          RTCPeerConnectionState.RTCPeerConnectionStateFailed =>
            _l10n.callPeerFailed,
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected =>
            _l10n.callPeerReconnecting,
          _ => _l10n.callPeerConnecting,
        },
      );
    };
    pc.onTrack = (event) async {
      if (event.streams.isEmpty || _ended) return;
      final renderer = RTCVideoRenderer();
      await renderer.initialize();
      if (_ended) {
        await renderer.dispose();
        return;
      }
      await _audio.remove(id)?.dispose();
      _audio[id] = renderer;
      renderer.srcObject = event.streams.first;
    };
    return pc;
  }

  Future<void> _poll() async {
    if (_polling || _ended || _local == null) return;
    _polling = true;
    try {
      final room = await _client
          .from('care_calls')
          .select()
          .eq('id', widget.callId)
          .single();
      if (room['ended_at'] != null ||
          DateTime.parse(
            room['expires_at'] as String,
          ).isBefore(DateTime.now())) {
        _ended = true;
        await _release();
        if (mounted) setState(() {});
        return;
      }
      final members = await _client
          .from('care_call_members')
          .select()
          .eq('call_id', widget.callId);
      for (final member in members) {
        final id = member['person_id'] as String;
        if (id == _pid) continue;
        if (member['status'] == 'joined' &&
            !_peers.containsKey(id) &&
            _pid.compareTo(id) < 0) {
          final pc = await _peer(id);
          final offer = await pc.createOffer();
          await pc.setLocalDescription(offer);
          await _send(id, {'type': 'offer', 'sdp': offer.sdp});
        } else if (member['status'] != 'joined' && _peers.containsKey(id)) {
          await _peers.remove(id)?.close();
          await _audio.remove(id)?.dispose();
          _described.remove(id);
          _candidates.remove(id);
          _states.remove(id);
        }
      }
      final signals = await _client
          .from('care_call_signals')
          .select()
          .eq('call_id', widget.callId)
          .eq('target_id', _pid)
          .gt('id', _lastSignal)
          .order('id')
          .limit(100);
      for (final signal in signals) {
        final id = signal['sender_id'] as String;
        final p = signal['payload'] as Map<String, dynamic>;
        final sender = members.where((m) => m['person_id'] == id).firstOrNull;
        // The member list was read a moment before the signals, so a
        // sender who has just joined can still show as invited. Leave
        // their signal for the next poll rather than losing the offer.
        if (sender?['status'] == 'invited') break;
        if (sender?['status'] != 'joined') {
          _lastSignal = signal['id'] as int;
          continue;
        }
        final pc = await _peer(id);
        if (p['type'] == 'offer' || p['type'] == 'answer') {
          await pc.setRemoteDescription(
            RTCSessionDescription(p['sdp'] as String, p['type'] as String),
          );
          _described.add(id);
          for (final c in _candidates.remove(id) ?? <RTCIceCandidate>[]) {
            await pc.addCandidate(c);
          }
          if (p['type'] == 'offer') {
            final answer = await pc.createAnswer();
            await pc.setLocalDescription(answer);
            await _send(id, {'type': 'answer', 'sdp': answer.sdp});
          }
        } else if (p['type'] == 'candidate') {
          final c = p['candidate'] as Map<String, dynamic>;
          final candidate = RTCIceCandidate(
            c['candidate'] as String?,
            c['sdpMid'] as String?,
            c['sdpMLineIndex'] as int?,
          );
          if (_described.contains(id)) {
            await pc.addCandidate(candidate);
          } else {
            (_candidates[id] ??= []).add(candidate);
          }
        }
        _lastSignal = signal['id'] as int;
      }
      if (mounted && !_ended) {
        setState(() {
          _members = members;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted && !_ended) {
        setState(() => _error = _l10n.callInterrupted);
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _leave() async {
    if (_ended) {
      if (mounted) Navigator.pop(context);
      return;
    }
    try {
      await _client.rpc(
        'respond_care_call',
        params: {
          'p_call_id': widget.callId,
          'p_action': _owner == _pid ? 'end' : 'left',
        },
      );
    } catch (_) {
      /* Always release the microphone, even while offline. */
    }
    _ended = true;
    await _release();
    ref.invalidate(incomingCareCallsProvider);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _release() async {
    _timer?.cancel();
    for (final pc in _peers.values.toList()) {
      await pc.close();
    }
    _peers.clear();
    for (final renderer in _audio.values.toList()) {
      await renderer.dispose();
    }
    _audio.clear();
    final stream = _local;
    _local = null;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await track.stop();
      }
      await stream.dispose();
    }
  }

  @override
  void dispose() {
    _ended = true;
    unawaited(_release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _ended,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(_l10n.callTitle),
        leading: IconButton(
          onPressed: _leave,
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(
                Icons.health_and_safety_outlined,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                _ended
                    ? _l10n.callEnded
                    : _ready
                    ? _l10n.callYourCircle
                    : _error != null
                    ? _l10n.callCouldNotConnect
                    : _l10n.callConnecting,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(_l10n.callKeepOpen),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(_error!),
                ),
              if (!_ended && !_ready && _error != null)
                OutlinedButton.icon(
                  onPressed: _starting ? null : _start,
                  icon: const Icon(Icons.refresh),
                  label: Text(_l10n.retryCall),
                ),
              Expanded(
                child: ListView(
                  children: [
                    for (final member in _members)
                      ListTile(
                        leading: Icon(
                          member['person_id'] == _pid
                              ? Icons.person
                              : Icons.person_outline,
                        ),
                        title: Text(member['name'] as String),
                        subtitle: Text(
                          member['person_id'] == _pid
                              ? (_muted ? _l10n.callYouMuted : _l10n.callYou)
                              : member['status'] == 'invited'
                              ? _l10n.callInvitedWaiting
                              : member['status'] == 'joined'
                              ? (_states[member['person_id']] ??
                                    _l10n.callPeerConnecting)
                              : member['status'] == 'declined'
                              ? _l10n.callDeclined
                              : _l10n.callLeft,
                        ),
                      ),
                  ],
                ),
              ),
              if (!_ended)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      tooltip: _muted ? _l10n.unmute : _l10n.mute,
                      onPressed: !_ready
                          ? null
                          : () {
                              for (final t
                                  in _local?.getAudioTracks() ??
                                      <MediaStreamTrack>[]) {
                                t.enabled = _muted;
                              }
                              setState(() => _muted = !_muted);
                            },
                      icon: Icon(_muted ? Icons.mic_off : Icons.mic),
                    ),
                    if (!kIsWeb) ...[
                      const SizedBox(width: 24),
                      IconButton.filledTonal(
                        tooltip: _l10n.speaker,
                        onPressed: !_ready
                            ? null
                            : () async {
                                try {
                                  await Helper.setSpeakerphoneOn(!_speaker);
                                  if (mounted) {
                                    setState(() => _speaker = !_speaker);
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _l10n.callAudioOutputFailed,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(_speaker ? Icons.volume_up : Icons.hearing),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                ),
                onPressed: _leave,
                icon: const Icon(Icons.call_end),
                label: Text(
                  _ended
                      ? _l10n.close
                      : _owner == _pid
                      ? _l10n.callEndForEveryone
                      : _l10n.callLeave,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
