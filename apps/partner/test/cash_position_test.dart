import 'package:flutter_test/flutter_test.dart';
import 'package:kaylo_partner/features/jobs/data/mock_jobs_repository.dart';
import 'package:kaylo_partner/features/jobs/domain/cash_position.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the mock ledger books cash jobs, survives a restart and settles', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = MockJobsRepository(prefs);
    final jobs = await repo.getJobs();
    final job = jobs.firstWhere((j) => j.payout > 0);
    expect(await repo.getCashPosition(), CashPosition.none);

    await repo.markCashCollected(job.id, amount: 1000);
    var position = await repo.getCashPosition();
    expect(position.cashInHand, 1000);
    expect(position.dueToKaylo, 150);
    expect(position.canAcceptCash, isTrue);

    // The default amount is the payout grossed up to the customer's price.
    await repo.markCashCollected(job.id);
    position = await repo.getCashPosition();
    final price = ((job.payout / 0.85) / 10).round() * 10.0;
    expect(position.cashInHand, 1000 + price);
    expect(position.dueToKaylo, closeTo(150 + price * 0.15, 0.01));
    repo.dispose();

    final restarted = MockJobsRepository(prefs);
    expect(await restarted.getCashPosition(), position);
    await restarted.settleCashDue();
    expect(await restarted.getCashPosition(), CashPosition.none);
    await expectLater(restarted.settleCashDue(), throwsStateError);
    restarted.dispose();
  });
}
