import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_core/services/notification_service.dart';
import 'package:kaylo_partner/features/notifications/data/partner_push_service.dart';

class _Push extends NotificationServiceStub {
  final tokens = StreamController<String>.broadcast();
  final messages = StreamController<PushMessage>.broadcast();
  int revocations = 0;
  int failedRevocations = 0;
  @override
  Future<String?> getToken() async =>
      revocations == 0 ? 'first' : 'fresh-$revocations';
  @override
  Future<void> deleteToken() async {
    if (failedRevocations > 0) {
      failedRevocations--;
      throw StateError('offline');
    }
    revocations++;
  }

  @override
  Stream<String> get onTokenRefresh => tokens.stream;
  @override
  Stream<PushMessage> get onMessage => messages.stream;
}

void main() {
  test(
    'registers, rotates, and unregisters the device before sign-out',
    () async {
      final service = _Push();
      final calls = <String>[];
      final binding = PartnerPushBinding(
        service: service,
        register: (token) async => calls.add('register:$token'),
        unregister: (token) async => calls.add('delete:$token'),
        onRequest: (_) async {},
      );
      await setActivePartnerPushBinding(binding);
      service.tokens.add('second');
      await Future<void>.delayed(Duration.zero);
      await clearPartnerPushToken();
      service.tokens.add('after-logout');
      await Future<void>.delayed(Duration.zero);
      expect(calls, [
        'register:first',
        'delete:first',
        'register:second',
        'delete:second',
      ]);
      expect(service.revocations, 1);
      await service.tokens.close();
      await service.messages.close();
    },
  );

  test('in-flight token registration is removed on sign-out', () async {
    final service = _Push();
    final pending = Completer<void>();
    final deleted = <String>[];
    final binding = PartnerPushBinding(
      service: service,
      register: (_) => pending.future,
      unregister: (token) async => deleted.add(token),
      onRequest: (_) async {},
    );
    final starting = binding.start();
    await Future<void>.delayed(Duration.zero);
    final stopping = binding.dispose();
    pending.complete();
    await starting;
    await stopping;
    expect(deleted, ['first']);
    await service.tokens.close();
    await service.messages.close();
  });

  test(
    'failed database cleanup still revokes FCM before a new person registers',
    () async {
      final service = _Push();
      final calls = <String>[];
      final old = PartnerPushBinding(
        service: service,
        register: (token) async => calls.add('old:$token'),
        unregister: (_) async => throw StateError('RLS session expired'),
        onRequest: (_) async {},
      );
      await setActivePartnerPushBinding(old);
      await clearPartnerPushToken();
      expect(service.revocations, 1);
      final next = PartnerPushBinding(
        service: service,
        register: (token) async => calls.add('next:$token'),
        unregister: (_) async {},
        onRequest: (_) async {},
      );
      await setActivePartnerPushBinding(next);
      expect(calls, ['old:first', 'next:fresh-1']);
      await clearPartnerPushToken();
      await service.tokens.close();
      await service.messages.close();
    },
  );

  test(
    'provider disposal before sign-out does not lose the revocation handle',
    () async {
      final service = _Push();
      final binding = PartnerPushBinding(
        service: service,
        register: (_) async {},
        unregister: (_) async => throw StateError('expired'),
        onRequest: (_) async {},
      );
      await setActivePartnerPushBinding(binding);
      await binding.dispose();
      expect(service.revocations, 0);
      await clearPartnerPushToken();
      expect(service.revocations, 1);
      await service.tokens.close();
      await service.messages.close();
    },
  );

  test('locale or profile rebuild keeps the active FCM token', () async {
    final service = _Push();
    final registered = <String>[];
    PartnerPushBinding bind() => PartnerPushBinding(
      service: service,
      register: (token) async => registered.add(token),
      unregister: (_) async {},
      onRequest: (_) async {},
    );
    final previous = bind();
    await setActivePartnerPushBinding(previous);
    await previous.dispose();
    await setActivePartnerPushBinding(bind());
    expect(service.revocations, 0);
    expect(registered, ['first', 'first']);
    await clearPartnerPushToken();
    await service.tokens.close();
    await service.messages.close();
  });

  test(
    'offline revocation is retried before the next binding starts',
    () async {
      final service = _Push();
      final registered = <String>[];
      PartnerPushBinding bind() => PartnerPushBinding(
        service: service,
        register: (token) async => registered.add(token),
        unregister: (_) async {},
        onRequest: (_) async {},
      );
      await setActivePartnerPushBinding(bind());
      service.failedRevocations = 1;
      await clearPartnerPushToken();
      expect(service.revocations, 0);
      await setActivePartnerPushBinding(bind());
      expect(service.revocations, 1);
      expect(registered, ['first', 'fresh-1']);
      await clearPartnerPushToken();
      await service.tokens.close();
      await service.messages.close();
    },
  );

  test(
    'only job request payloads with a safe booking id produce local alerts',
    () {
      expect(
        isPartnerJobRequest(
          const PushMessage(
            data: {'type': 'new_job_request', 'booking_id': 'a1-b2'},
          ),
        ),
        isTrue,
      );
      expect(
        isPartnerJobRequest(
          const PushMessage(data: {'type': 'care_call', 'booking_id': 'a1-b2'}),
        ),
        isFalse,
      );
      expect(
        isPartnerJobRequest(
          const PushMessage(
            data: {'type': 'booking_request', 'booking_id': '../profile'},
          ),
        ),
        isFalse,
      );
      expect(
        isPartnerJobRequest(
          const PushMessage(data: {'type': 'booking_request'}),
        ),
        isFalse,
      );
    },
  );
}
