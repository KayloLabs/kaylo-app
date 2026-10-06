import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../jobs/application/jobs_providers.dart';
import '../../jobs/domain/job.dart';

class DailyEarning {
  final String dayLabel;
  final DateTime date;
  final double amount;
  final bool isToday;

  const DailyEarning({
    required this.dayLabel,
    required this.date,
    required this.amount,
    required this.isToday,
  });
}

class EarningsSummary {
  final double todayTotal;
  final int todayJobsCount;
  final double weekTotal;
  final int weekJobsCount;
  final double averagePerJob;
  final List<DailyEarning> last7Days;
  final List<Job> completedJobs;

  const EarningsSummary({
    required this.todayTotal,
    required this.todayJobsCount,
    required this.weekTotal,
    required this.weekJobsCount,
    required this.averagePerJob,
    required this.last7Days,
    required this.completedJobs,
  });
}

final earningsSummaryProvider = Provider<EarningsSummary>((ref) {
  final jobs = ref.watch(jobsStreamProvider).asData?.value ?? [];
  final completed = jobs.where((j) => j.isCompleted).toList()
    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final sevenDaysAgo = todayStart.subtract(const Duration(days: 6));

  double todayTotal = 0.0;
  int todayCount = 0;
  double weekTotal = 0.0;
  int weekCount = 0;

  for (final job in completed) {
    final jobDate = DateTime(
      job.scheduledAt.year,
      job.scheduledAt.month,
      job.scheduledAt.day,
    );

    if (!jobDate.isBefore(todayStart)) {
      todayTotal += job.payout;
      todayCount++;
    }

    if (!jobDate.isBefore(sevenDaysAgo)) {
      weekTotal += job.payout;
      weekCount++;
    }
  }

  // Calculate 7-day breakdown
  final last7Days = <DailyEarning>[];
  for (int i = 6; i >= 0; i--) {
    final d = todayStart.subtract(Duration(days: i));
    final nextD = d.add(const Duration(days: 1));

    double dayAmount = 0.0;
    for (final job in completed) {
      if (!job.scheduledAt.isBefore(d) && job.scheduledAt.isBefore(nextD)) {
        dayAmount += job.payout;
      }
    }

    final dayName = DateFormat('E').format(d); // Mon, Tue, ...
    last7Days.add(
      DailyEarning(
        dayLabel: i == 0 ? 'Today' : dayName,
        date: d,
        amount: dayAmount,
        isToday: i == 0,
      ),
    );
  }

  final avg = weekCount > 0 ? (weekTotal / weekCount) : 0.0;

  return EarningsSummary(
    todayTotal: todayTotal,
    todayJobsCount: todayCount,
    weekTotal: weekTotal,
    weekJobsCount: weekCount,
    averagePerJob: avg,
    last7Days: last7Days,
    completedJobs: completed,
  );
});
