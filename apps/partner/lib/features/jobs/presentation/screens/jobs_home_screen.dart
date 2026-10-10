import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/section_header.dart';

import '../../../profile/application/profile_providers.dart';
import '../../../earnings/application/earnings_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/jobs_providers.dart';
import '../widgets/job_card.dart';

class JobsHomeScreen extends ConsumerWidget {
  const JobsHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(workerProfileProvider).asData?.value;
    final district = profile?.district;
    final isOnline = ref.watch(dutyStatusProvider).asData?.value ?? true;
    final earnings = ref.watch(earningsSummaryProvider);
    final activeJobAsync = ref.watch(activeJobProvider);
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return Scaffold(
      appBar: AppBar(
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
              [
                if ((profile?.name ?? '').isNotEmpty) profile!.name,
                if ((district ?? '').isNotEmpty) district!,
              ].join(' • '),
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
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          100,
        ),
        children: [
          // Duty Toggle Pill
          _DutyTogglePill(
            isOnline: isOnline,
            district: district,
            onChanged: (online) async {
              KayloFeedback.press();
              try {
                await ref.read(dutySwitchProvider).set(online);
              } catch (_) {
                if (context.mounted) {
                  KayloSnackbar.showError(context, l10n.dutyUpdateFailed);
                }
              }
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
                  value: '${(profile?.rating ?? 0).toStringAsFixed(1)} ★',
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(title: l10n.newRequests(requests.length)),
                    const SizedBox(height: AppSpacing.m),
                    if (requests.isEmpty)
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
                      )
                    else
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
        ],
      ),
    );
  }
}

class _DutyTogglePill extends StatelessWidget {
  final bool isOnline;
  final String? district;
  final ValueChanged<bool> onChanged;

  const _DutyTogglePill({
    required this.isOnline,
    required this.district,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isOnline
        ? AppColors.brandPrimary.withValues(alpha: isDark ? 0.2 : 0.1)
        : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceAlt);

    final borderColor = isOnline
        ? AppColors.brandPrimary.withValues(alpha: 0.4)
        : (isDark ? AppColors.borderDark : AppColors.border);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: borderColor, width: 1.5),
      ),
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
                    color: isOnline
                        ? AppColors.brandPrimary
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                  ),
                ),
                Text(
                  !isOnline
                      ? l10n.dutyNotReceivingRequests
                      : (district ?? '').isEmpty
                      ? l10n.dutyTakingOrdersAnywhere
                      : l10n.dutyTakingOrders(district!),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
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
