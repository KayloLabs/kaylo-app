import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/care_models.dart';

class SosCallState {
  const SosCallState({
    required this.status,
    required this.attempted,
    required this.total,
    this.name,
    this.error,
  });

  factory SosCallState.fromMap(Map<dynamic, dynamic> value) => SosCallState(
    status: value['status'] as String? ?? 'idle',
    attempted: value['attempted'] as int? ?? 0,
    total: value['total'] as int? ?? 0,
    name: value['name'] as String?,
    error: value['error'] as String?,
  );

  final String status;
  final int attempted;
  final int total;
  final String? name;
  final String? error;
  bool get running => status == 'calling' || status == 'waiting';
}

abstract class SosPhoneCalls {
  bool get supported;
  Stream<SosCallState> get updates;
  Future<SosCallState> start(List<EmergencyContact> contacts);
  Future<SosCallState> stop();
}

final sosPhoneCallsProvider = Provider<SosPhoneCalls>(
  (ref) => AndroidSosPhoneCalls(),
);

class AndroidSosPhoneCalls implements SosPhoneCalls {
  static const _methods = MethodChannel('kaylo/sos_calls');
  static const _events = EventChannel('kaylo/sos_call_updates');

  @override
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Stream<SosCallState> get updates => _events.receiveBroadcastStream().map(
    (event) => SosCallState.fromMap(event as Map<dynamic, dynamic>),
  );

  @override
  Future<SosCallState> start(List<EmergencyContact> contacts) async {
    final ordered = [
      ...contacts.where((contact) => contact.isPrimary),
      ...contacts.where((contact) => !contact.isPrimary),
    ];
    final result = await _methods.invokeMapMethod<String, dynamic>('start', {
      'contacts': [
        for (final contact in ordered)
          {'name': contact.name, 'phone': contact.phone},
      ],
    });
    return SosCallState.fromMap(result!);
  }

  @override
  Future<SosCallState> stop() async => SosCallState.fromMap(
    (await _methods.invokeMapMethod<String, dynamic>('stop'))!,
  );
}
