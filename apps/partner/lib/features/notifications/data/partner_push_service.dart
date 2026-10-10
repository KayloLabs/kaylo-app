import 'dart:async';
import 'package:kaylo_core/services/notification_service.dart';

PartnerPushBinding? _activeBinding;
// Retained after provider disposal: logout may run after the auth-dependent
// provider has already torn down its subscriptions.
NotificationService? _sessionService;
NotificationService? _pendingRevocation;
Future<void> _lifecycle = Future.value();

Future<void> _serializeLifecycle(Future<void> Function() action) {
  final result = _lifecycle.then((_) => action());
  _lifecycle = result.catchError((Object _) {});
  return result;
}

Future<void> setActivePartnerPushBinding(PartnerPushBinding binding) =>
    _serializeLifecycle(() async {
      final previous = _activeBinding;
      await previous?.dispose();
      if (binding._disposed) return;
      // If revocation failed offline, never reuse that token for a new person.
      // FCM also persists this pending work across an application restart.
      final pending = _pendingRevocation;
      if (pending != null) {
        await pending.deleteToken();
        _pendingRevocation = null;
      }
      _activeBinding = binding;
      _sessionService = binding.service;
      await binding.start();
    });

/// Called before ending Firebase auth where possible. Database cleanup can
/// fail after expiry, so invalidate FCM separately. A UI/provider rebuild only
/// disposes the binding and does not revoke a signed-in person's active token.
Future<void> clearPartnerPushToken() => _serializeLifecycle(() async {
  final binding = _activeBinding;
  _activeBinding = null;
  await binding?.dispose();
  final service = _sessionService ?? _pendingRevocation;
  _sessionService = null;
  if (service == null) return;
  _pendingRevocation = service;
  try {
    await service.deleteToken();
    _pendingRevocation = null;
  } catch (_) {
    // Persisted by FCM; retried on the next start before token registration.
  }
});

/// Serializes token rotation and teardown so a late token cannot resurrect a
/// registration after sign-out. The callbacks make this lifecycle testable.
class PartnerPushBinding {
  PartnerPushBinding({
    required this.service,
    required this.register,
    required this.unregister,
    required this.onRequest,
  });
  final NotificationService service;
  final Future<void> Function(String token) register;
  final Future<void> Function(String token) unregister;
  final Future<void> Function(PushMessage message) onRequest;
  StreamSubscription<String>? _tokens;
  StreamSubscription<PushMessage>? _messages;
  Future<void> _queue = Future.value();
  String? _token;
  bool _disposed = false;
  bool _started = false;
  Future<void>? _disposing;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    try {
      await service.initialize();
      if (_disposed) return;
      _tokens = service.onTokenRefresh.listen(_register);
      _messages = service.onMessage.listen((message) {
        if (!_disposed && isPartnerJobRequest(message)) {
          unawaited(onRequest(message).catchError((Object _) {}));
        }
      });
      final token = await service.getToken();
      if (token != null) await _register(token);
    } catch (_) {
      // An OS permission refusal never prevents signing in or working.
    }
  }

  Future<void> _register(String token) {
    _queue = _queue
        .then((_) async {
          if (_disposed || token == _token || token.isEmpty) return;
          if (_token != null) await unregister(_token!);
          _token = null;
          await register(token);
          _token = token;
        })
        .catchError((Object _) {});
    return _queue;
  }

  Future<void> dispose() => _disposing ??= _dispose();

  Future<void> _dispose() async {
    _disposed = true;
    await _tokens?.cancel();
    await _messages?.cancel();
    await _queue;
    final token = _token;
    _token = null;
    if (token != null) {
      try {
        await unregister(token);
      } catch (_) {}
    }
    if (identical(_activeBinding, this)) _activeBinding = null;
  }
}

bool isPartnerJobRequest(PushMessage message) {
  final type = message.data['type'];
  final id = message.data['booking_id'];
  return (type == 'booking_request' || type == 'new_job_request') &&
      id is String &&
      RegExp(r'^[a-zA-Z0-9_-]{1,80}$').hasMatch(id);
}

int partnerRequestNotificationId(String id) {
  var value = 0x811c9dc5;
  for (final code in id.codeUnits) {
    value = ((value ^ code) * 0x01000193) & 0x7fffffff;
  }
  return value;
}
