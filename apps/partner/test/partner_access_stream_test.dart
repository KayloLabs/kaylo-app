import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/auth/data/partner_access_stream.dart';
import 'package:kaylo_partner/features/auth/domain/partner_auth_repository.dart';

void main() {
  const first = PartnerAccess(PartnerAccessStatus.ready, workerId: 'first');
  const second = PartnerAccess(PartnerAccessStatus.ready, workerId: 'second');

  test(
    'a synchronous account change during the first event is not lost',
    () async {
      final changes = StreamController<PartnerAccess>.broadcast();
      final received = <PartnerAccess>[];
      final completed = Completer<void>();
      final subscription =
          watchPartnerAccess(
            changes: changes.stream,
            initial: () => first,
          ).listen((access) {
            received.add(access);
            if (access == first) changes.add(second);
            if (access == second) completed.complete();
          });
      await completed.future.timeout(const Duration(seconds: 2));
      expect(received, [first, second]);
      await subscription.cancel();
      await changes.close();
    },
  );

  test(
    'an old initial lookup cannot overwrite a newer account event',
    () async {
      final changes = StreamController<PartnerAccess>.broadcast();
      final initial = Completer<PartnerAccess>();
      final received = <PartnerAccess>[];
      final subscription = watchPartnerAccess(
        changes: changes.stream,
        initial: () => initial.future,
      ).listen(received.add);
      changes.add(second);
      await Future<void>.delayed(Duration.zero);
      initial.complete(first);
      await Future<void>.delayed(Duration.zero);
      expect(received, [second]);
      await subscription.cancel();
      await changes.close();
    },
  );

  test(
    'cancellation releases the change listener and ignores pending initial work',
    () async {
      final changes = StreamController<PartnerAccess>.broadcast();
      final initial = Completer<PartnerAccess>();
      final received = <PartnerAccess>[];
      final subscription = watchPartnerAccess(
        changes: changes.stream,
        initial: () => initial.future,
      ).listen(received.add);
      expect(changes.hasListener, isTrue);
      await subscription.cancel();
      expect(changes.hasListener, isFalse);
      initial.complete(first);
      await Future<void>.delayed(Duration.zero);
      expect(received, isEmpty);
      await changes.close();
    },
  );
}
