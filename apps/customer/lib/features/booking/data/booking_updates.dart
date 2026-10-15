import 'dart:async';
import 'package:kaylo_core/models/booking.dart';

/// Serializes reads without losing an event received while a read is pending.
/// Each watch owns and disposes its subscription and fallback timer.
Stream<List<Booking>> watchBookingSnapshots({
  required Future<List<Booking>> Function() load,
  required Stream<void> changes,
  Duration refreshInterval = const Duration(seconds: 10),
}) => Stream<List<Booking>>.multi((sink) {
  var stopped = false;
  var loading = false;
  var dirty = false;
  Future<void> refresh() async {
    if (stopped) return;
    if (loading) {
      dirty = true;
      return;
    }
    loading = true;
    do {
      dirty = false;
      try {
        final rows = await load().timeout(const Duration(seconds: 15));
        if (!stopped) sink.add(rows);
      } catch (error, stack) {
        if (!stopped) sink.addError(error, stack);
      }
    } while (dirty && !stopped);
    loading = false;
  }

  final subscription = changes.listen(
    (_) => unawaited(refresh()),
    onError: (Object _) => unawaited(refresh()),
  );
  final timer = Timer.periodic(refreshInterval, (_) => unawaited(refresh()));
  unawaited(refresh());
  sink.onCancel = () async {
    stopped = true;
    timer.cancel();
    await subscription.cancel();
  };
});
