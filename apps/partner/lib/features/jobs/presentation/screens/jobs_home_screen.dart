import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_chip.dart';
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/section_header.dart';

import '../../../auth/application/partner_session.dart';
import '../../../earnings/application/earnings_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/jobs_providers.dart';
import '../../application/jobs_sort.dart';
import '../widgets/job_card.dart';

class JobsHomeScreen extends ConsumerWidget {
  const JobsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worker = ref.watch(partnerWorkerProfileProvider);
    final isOnline = ref.watch(dutyStatusProvider).asData?.value ?? true;
    final earnings = ref.watch(earningsSummaryProvider);
    final activeJobAsync = ref.watch(activeJobProvider);
    final rawRequestsAsync = ref.watch(incomingRequestsProvider);
    final requestsAsync = ref.watch(sortedIncomingRequestsProvider);
    final activeSort = ref.watch(jobSortProvider);
    final activeFilters = ref.watch(jobServiceFilterProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appTitle,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${worker.name} • Kannur',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.refreshJobsTooltip,
                onPressed: () {
                  KayloFeedback.tap();
                  ref.invalidate(jobsStreamProvider);
                },
              ),
            ],
            flexibleSpace: const KayloLiquidGlass(
              borderRadius: 0,
              child: SizedBox.expand(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
          // Duty Toggle Pill
          _DutyTogglePill(
            isOnline: isOnline,
            onChanged: (online) {
              KayloFeedback.press();
              ref.read(jobsRepositoryProvider).setDuty(online);
            },
          ),
          const SizedBox(height: AppSpacing.m),

          // Today's Summary Strip
          Row(
            children: [
              Expanded(
                child: _SummaryBox(
                  label: l10n.todaysPay,
                  value: formatRupees(earnings.todayTotal),
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _SummaryBox(
                  label: l10n.jobsToday,
                  value: '${earnings.todayJobsCount}',
                ),
              ),
              const SizedBox(width: AppSpacing.s),
              Expanded(
                child: _SummaryBox(
                  label: l10n.rating,
                  value: '${worker.rating} ★',
                  color: AppColors.secondaryAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // Active Job in Progress (if any)
          activeJobAsync.when(
            data: (activeJob) {
              if (activeJob == null) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(title: l10n.activeJob),
                  const SizedBox(height: AppSpacing.s),
                  JobCard(job: activeJob),
                  const SizedBox(height: AppSpacing.l),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // Incoming Requests (Only when Online)
          if (!isOnline) ...[
            const SizedBox(height: AppSpacing.l),
            EmptyState(
              title: l10n.offlineTitle,
              description: l10n.offlineDescription,
              icon: Icons.power_settings_new_rounded,
            ),
          ] else ...[
            requestsAsync.when(
              data: (requests) {
                final rawRequests = rawRequestsAsync.asData?.value ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: l10n.newRequests(requests.length)),
                    const SizedBox(height: AppSpacing.s),
                    _SortAndFilterChipsRow(
                      activeSort: activeSort,
                      activeFilters: activeFilters,
                    ),
                    const SizedBox(height: AppSpacing.m),
                    if (requests.isEmpty) ...[
                      if (rawRequests.isNotEmpty && activeFilters.isNotEmpty)
                        EmptyState(
                          title: l10n.filterEmptyTitle,
                          description: l10n.filterEmptySubtitle,
                          icon: Icons.filter_alt_off_rounded,
                          actionText: l10n.clearFilters,
                          onActionPressed: () {
                            KayloFeedback.tap();
                            ref.read(jobServiceFilterProvider.notifier).clear();
                          },
                        )
                      else
                        KayloCard(
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.brandPrimary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.m),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.searchingForRequests,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      l10n.searchingForRequestsSubtitle,
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
                            ],
                          ),
                        ),
                    ] else
                      for (final job in requests) ...[
                        JobCard(job: job),
                        const SizedBox(height: AppSpacing.m),
                      ],
                  ],
                );
              },
              loading: () => const Center(child: KayloLoader()),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ]),
      ),
    ),
  ],
),
    );
  }
}

class _SortAndFilterChipsRow extends ConsumerWidget {
  final JobSort activeSort;
  final Set<String> activeFilters;

  const _SortAndFilterChipsRow({
    required this.activeSort,
    required this.activeFilters,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const serviceOptions = [
      'Plumbing',
      'Electrical',
      'Appliances',
      'Carpentry',
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Sort chips
          _SelectableKayloChip(
            label: l10n.sortNearest,
            icon: Icons.near_me_rounded,
            isSelected: activeSort == JobSort.nearest,
            onTap: () {
              ref.read(jobSortProvider.notifier).setSort(JobSort.nearest);
            },
          ),
          const SizedBox(width: AppSpacing.s),
          _SelectableKayloChip(
            label: l10n.sortHighestPayout,
            icon: Icons.currency_rupee_rounded,
            isSelected: activeSort == JobSort.highestPayout,
            onTap: () {
              ref.read(jobSortProvider.notifier).setSort(JobSort.highestPayout);
            },
          ),
          const SizedBox(width: AppSpacing.s),
          _SelectableKayloChip(
            label: l10n.sortSoonest,
            icon: Icons.schedule_rounded,
            isSelected: activeSort == JobSort.soonest,
            onTap: () {
              ref.read(jobSortProvider.notifier).setSort(JobSort.soonest);
            },
          ),

          // Divider between sorts and filters
          Container(
            height: 20,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),

          // Filter chips
          for (final service in serviceOptions) ...[
            _SelectableKayloChip(
              label: service,
              isSelected: activeFilters.contains(service),
              onTap: () {
                ref.read(jobServiceFilterProvider.notifier).toggle(service);
              },
            ),
            const SizedBox(width: AppSpacing.s),
          ],
        ],
      ),
    );
  }
}

class _SelectableKayloChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableKayloChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        KayloFeedback.selection();
        onTap();
      },
      child: KayloChip(
        label: label,
        icon: icon,
        variant: isSelected ? KayloChipVariant.brand : KayloChipVariant.neutral,
      ),
    );
  }
}

class _DutyTogglePill extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onChanged;

  const _DutyTogglePill({required this.isOnline, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayColor = isOnline
        ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.22 : 0.12)
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03));

    final titleColor = isOnline
        ? (isDark ? AppColors.brandPrimaryBright : AppColors.brandPrimary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary);

    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: KayloLiquidGlass(
        borderRadius: 28,
        colorOverlay: overlayColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isOnline
                    ? AppColors.brandPrimaryBright
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isOnline ? l10n.dutyOnline : l10n.dutyOffline,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  Text(
                    isOnline
                        ? l10n.dutyTakingOrders('Kannur')
                        : l10n.dutyNotReceivingRequests,
                    style: TextStyle(
                      fontSize: 11,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: isOnline,
              onChanged: onChanged,
              activeTrackColor: AppColors.brandPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _SummaryBox({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KayloCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color:
                    color ??
                    (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
