import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/section_header.dart';

import '../../../../core/router/routes.dart';
import '../../application/earnings_providers.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = ref.watch(earningsSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Earnings'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(Routes.history),
            icon: const Icon(Icons.history_rounded),
            label: const Text('History'),
          ),
          const SizedBox(width: AppSpacing.s),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          100,
        ),
        children: [
          // Weekly Hero Banner
          KayloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "THIS WEEK'S EARNINGS",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(
                  formatRupees(summary.weekTotal),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandPrimary,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.brandPrimaryBright,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      '${formatRupees(summary.todayTotal)} earned today (${summary.todayJobsCount} jobs)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // 7-day Bar Chart
                _WeeklyBarChart(days: summary.last7Days),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // 2 Stats Cards
          Row(
            children: [
              Expanded(
                child: KayloCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Jobs',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary.completedJobs.length}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: KayloCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average / Job',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatRupees(summary.averagePerJob),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Completed Jobs History Breakdown
          SectionHeader(
            title: 'Completed Jobs (${summary.completedJobs.length})',
          ),
          const SizedBox(height: AppSpacing.m),

          if (summary.completedJobs.isEmpty)
            const EmptyState(
              title: 'No completed jobs yet',
              description:
                  'Completed jobs will appear here with payout summaries.',
              icon: Icons.receipt_long_outlined,
            )
          else
            for (final job in summary.completedJobs) ...[
              KayloCard(
                onTap: () => context.push('${Routes.jobs}/${job.id}'),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(
                          alpha: isDark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.brandPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.serviceName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${job.customerName} • ${DateFormat.MMMd().add_jm().format(job.scheduledAt)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+${formatRupees(job.payout)}',
                      style: const TextStyle(
                        color: AppColors.brandPrimaryBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s),
            ],
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyEarning> days;

  const _WeeklyBarChart({required this.days});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxAmount = max(
      days.fold<double>(0.0, (prev, e) => max(prev, e.amount)),
      1000.0,
    );

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days) ...[
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.amount > 0)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '₹${day.amount.toInt()}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: day.isToday
                                    ? AppColors.brandPrimary
                                    : (isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: max(12.0, (day.amount / maxAmount) * 80.0),
                          decoration: BoxDecoration(
                            color: day.isToday
                                ? AppColors.brandPrimary
                                : (day.amount > 0
                                      ? AppColors.brandPrimary.withValues(
                                          alpha: isDark ? 0.35 : 0.25,
                                        )
                                      : (isDark
                                            ? Colors.white10
                                            : Colors.black12)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          day.dayLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: day.isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: day.isToday
                                ? (isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary)
                                : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
