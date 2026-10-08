import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_chip.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/jobs_providers.dart';
import '../../domain/job.dart';
import '../../domain/relative_time.dart';
import '../job_stage_text.dart';

class JobCard extends ConsumerWidget {
  final Job job;
  final bool isCompact;

  const JobCard({super.key, required this.job, this.isCompact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final IconData serviceIcon;
    switch (job.serviceIcon) {
      case 'electrical':
        serviceIcon = Icons.bolt_rounded;
        break;
      case 'appliances':
        serviceIcon = Icons.kitchen_rounded;
        break;
      case 'carpentry':
        serviceIcon = Icons.handyman_rounded;
        break;
      case 'plumbing':
      default:
        serviceIcon = Icons.plumbing_rounded;
        break;
    }

    return KayloCard(
      onTap: () => context.push('${Routes.jobs}/${job.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Service Name + Payout
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(
                    alpha: isDark ? 0.2 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  serviceIcon,
                  color: AppColors.brandPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.serviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.navigation_rounded,
                          size: 13,
                          color: AppColors.farmAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${job.distanceKm} km away',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.farmAccent,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '• ${formatRelativeScheduled(job.scheduledAt, l10n)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatRupees(job.payout),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  Text(
                    l10n.payout,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Customer and address
          Container(
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_pin_circle_outlined,
                  size: 18,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    '${job.customerName} • ${job.addressLine}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          if (job.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              '"${job.notes}"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Action buttons for requested stage
          if (job.isRequested) ...[
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                Expanded(
                  child: KayloButton(
                    text: l10n.decline,
                    variant: KayloButtonVariant.secondary,
                    onPressed: () {
                      KayloFeedback.tap();
                      ref.read(jobsRepositoryProvider).rejectJob(job.id);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  flex: 2,
                  child: KayloButton(
                    text: l10n.acceptJob,
                    variant: KayloButtonVariant.primary,
                    onPressed: () {
                      KayloFeedback.press();
                      ref.read(jobsRepositoryProvider).acceptJob(job.id);
                    },
                  ),
                ),
              ],
            ),
          ],

          // Active stage status and advance
          if (job.isActive) ...[
            const SizedBox(height: AppSpacing.m),
            Row(
              children: [
                KayloChip(
                  label: job.stage.text(l10n),
                  icon: Icons.sync_rounded,
                  variant: KayloChipVariant.brand,
                ),
                const Spacer(),
                SizedBox(
                  width: 140,
                  child: KayloButton(
                    text: job.stage.actionText(l10n),
                    onPressed: () {
                      KayloFeedback.press();
                      ref.read(jobsRepositoryProvider).advanceJob(job.id);
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
