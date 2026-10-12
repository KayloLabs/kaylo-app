import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../jobs/application/jobs_providers.dart';
import '../../jobs/domain/cash_position.dart';

/// The worker's cash in hand and commission due, live from the backend or the
/// mock ledger. Errors carry [LiveJobsPending] when actions are unavailable.
final cashPositionProvider = StreamProvider<CashPosition>((ref) {
  return ref.watch(jobsRepositoryProvider).watchCashPosition();
});
