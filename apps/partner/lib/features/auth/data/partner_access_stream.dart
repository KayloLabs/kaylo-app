import 'dart:async';
import '../domain/partner_auth_repository.dart';

/// Attach before publishing the initial snapshot. A listener may immediately
/// change accounts in response to that snapshot, and an async initial lookup
/// must never overwrite an event that has already reported a newer session.
Stream<PartnerAccess> watchPartnerAccess({
  required Stream<PartnerAccess> changes,
  required FutureOr<PartnerAccess> Function() initial,
}) => Stream.multi((controller) {
  var cancelled = false;
  var receivedChange = false;
  final subscription = changes.listen(
    (access) {
      receivedChange = true;
      controller.add(access);
    },
    onError: (Object error, StackTrace stack) {
      receivedChange = true;
      controller.addError(error, stack);
    },
    onDone: () {
      cancelled = true;
      controller.close();
    },
  );
  unawaited(
    Future<PartnerAccess>.sync(initial).then(
      (access) {
        if (!cancelled && !receivedChange) controller.add(access);
      },
      onError: (Object error, StackTrace stack) {
        if (!cancelled && !receivedChange) controller.addError(error, stack);
      },
    ),
  );
  controller.onCancel = () {
    cancelled = true;
    return subscription.cancel();
  };
});
