import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo/features/care/application/sos_phone_calls.dart';
import 'package:kaylo/features/care/domain/care_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const methods = MethodChannel('kaylo/sos_calls');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(methods, null));

  test(
    'SIM calls put the primary contact first and preserve phone numbers',
    () async {
      MethodCall? request;
      messenger.setMockMethodCallHandler(methods, (call) async {
        request = call;
        return {
          'status': 'calling',
          'attempted': 1,
          'total': 2,
          'name': 'Primary',
        };
      });
      final state = await AndroidSosPhoneCalls().start([
        const EmergencyContact(
          id: 'second',
          name: 'Second',
          relation: 'Child',
          phone: '+91 9000000001',
        ),
        const EmergencyContact(
          id: 'primary',
          name: 'Primary',
          relation: 'Child',
          phone: '+91 9000000002',
          isPrimary: true,
        ),
      ]);
      final contacts = (request!.arguments as Map)['contacts'] as List;
      expect(request!.method, 'start');
      expect((contacts.first as Map)['name'], 'Primary');
      expect((contacts.first as Map)['phone'], '+91 9000000002');
      expect(state.running, isTrue);
      expect(state.attempted, 1);
    },
  );

  test('stopping the sequence returns a stopped state', () async {
    messenger.setMockMethodCallHandler(methods, (call) async {
      expect(call.method, 'stop');
      return {'status': 'stopped', 'attempted': 1, 'total': 2};
    });
    final state = await AndroidSosPhoneCalls().stop();
    expect(state.running, isFalse);
    expect(state.total, 2);
  });

  test(
    'denied permission is surfaced instead of reported as a successful call',
    () async {
      messenger.setMockMethodCallHandler(methods, (_) async {
        throw PlatformException(code: 'permission-denied');
      });
      await expectLater(
        AndroidSosPhoneCalls().start([]),
        throwsA(isA<PlatformException>()),
      );
    },
  );
}
