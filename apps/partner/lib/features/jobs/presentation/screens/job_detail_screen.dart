import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_chip.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/jobs_providers.dart';
import '../../domain/geo.dart';
import '../../domain/job.dart';
import '../job_stage_text.dart';
import '../widgets/job_map.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

  Future<void> _callCustomer(BuildContext context, String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        KayloSnackbar.showError(context, 'Unable to open dialler');
      }
    }
  }

  Future<void> _navigate(BuildContext context, String address) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      KayloSnackbar.showInfo(
        context,
        'Navigation is unavailable on this device',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobDetailProvider(jobId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Detail'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Center(
              child: EmptyState(
                title: 'Job not found',
                description: 'This job may have been removed or expired.',
                icon: Icons.search_off_rounded,
              ),
            );
          }
          return _JobDetailContent(
            job: job,
            isDark: isDark,
            onNavigate: _navigate,
          );
        },
        loading: () => const Center(child: KayloLoader()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
      bottomNavigationBar: jobAsync.whenOrNull(
        data: (job) {
          if (job == null) return null;
          return _ActionBar(
            job: job,
            onCall: _callCustomer,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _JobDetailContent extends StatelessWidget {
  final Job job;
  final bool isDark;
  final Future<void> Function(BuildContext, String) onNavigate;

  const _JobDetailContent({
    required this.job,
    required this.isDark,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chipVariant = switch (job.stage) {
      JobStage.completed => KayloChipVariant.success,
      JobStage.cancelled => KayloChipVariant.error,
      JobStage.requested => KayloChipVariant.warning,
      _ => KayloChipVariant.brand,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        AppSpacing.m,
        AppSpacing.l,
        120,
      ),
      children: [
        // Hero payout + status card
        KayloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(
                        alpha: isDark ? 0.2 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _serviceIcon(job.serviceIcon),
                      color: AppColors.brandPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.serviceName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        KayloChip(
                          label: job.stage.text(l10n),
                          variant: chipVariant,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatRupees(job.payout),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // Customer & location
        KayloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: 'Customer',
                value: job.customerName,
              ),
              _divider(isDark),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: job.customerPhone,
              ),
              _divider(isDark),
              const SizedBox(height: AppSpacing.s),
              JobMap(
                job: job,
                height: 180,
                showExpandButton: true,
                onOpenGoogleMaps: () => onNavigate(context, job.addressLine),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.s,
                  bottom: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.near_me_outlined,
                      size: 16,
                      color: AppColors.farmAccent,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${job.distanceKm} km · ${l10n.aboutMinutes(etaMinutes(job.distanceKm))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.farmAccent,
                          ),
                    ),
                  ],
                ),
              ),
              _divider(isDark),
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: job.addressLine,
                multiLine: true,
              ),
              _divider(isDark),
              _DetailRow(
                icon: Icons.schedule_rounded,
                label: 'Scheduled',
                value: DateFormat.MMMd().add_jm().format(job.scheduledAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),

        // Customer notes
        if (job.notes.isNotEmpty) ...[
          KayloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer Notes',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.s),
                Text(job.notes, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.m),
        ],

        // Stage progression timeline
        KayloCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progress',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: AppSpacing.m),
              _StageTimeline(currentStage: job.stage),
            ],
          ),
        ),
      ],
    );
  }

  Divider _divider(bool isDark) => Divider(
    height: 1,
    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
  );

  IconData _serviceIcon(String icon) => switch (icon) {
    'electrical' => Icons.bolt_rounded,
    'appliances' => Icons.kitchen_rounded,
    'carpentry' => Icons.handyman_rounded,
    _ => Icons.plumbing_rounded,
  };
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool multiLine;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.m),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _StageTimeline extends StatelessWidget {
  final JobStage currentStage;

  const _StageTimeline({required this.currentStage});

  static const _stages = [
    JobStage.requested,
    JobStage.accepted,
    JobStage.onTheWay,
    JobStage.arrived,
    JobStage.inProgress,
    JobStage.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        for (int i = 0; i < _stages.length; i++) ...[
          Row(
            children: [
              _StepDot(
                isDone: _stages.indexOf(currentStage) >= i,
                isCurrent: _stages[i] == currentStage,
              ),
              const SizedBox(width: AppSpacing.m),
              Text(
                _stages[i].text(l10n),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: _stages[i] == currentStage
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: _stages[i] == currentStage
                      ? AppColors.brandPrimary
                      : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (i < _stages.length - 1)
            Padding(
              padding: const EdgeInsets.only(left: 9),
              child: Container(
                width: 2,
                height: 20,
                color: _stages.indexOf(currentStage) > i
                    ? AppColors.brandPrimary.withValues(alpha: 0.4)
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool isDone;
  final bool isCurrent;

  const _StepDot({required this.isDone, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.brandPrimary
            : (isDone
                  ? AppColors.brandPrimary.withValues(alpha: 0.4)
                  : Colors.transparent),
        shape: BoxShape.circle,
        border: Border.all(
          color: isDone
              ? AppColors.brandPrimary
              : Colors.grey.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: isDone
          ? const Icon(Icons.check, size: 12, color: Colors.white)
          : null,
    );
  }
}

// ---------------------------------------------------------------------------

class _ActionBar extends ConsumerWidget {
  final Job job;
  final Future<void> Function(BuildContext, String) onCall;

  const _ActionBar({
    required this.job,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    if (job.isCompleted) {
      return SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          0,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Job completed • ${formatRupees(job.payout)} earned',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.s),
            KayloButton(
              text: 'Back to Jobs',
              onPressed: () => context.go(Routes.jobs),
            ),
          ],
        ),
      );
    }
    if (job.isCancelled) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        AppSpacing.l,
        0,
        AppSpacing.l,
        AppSpacing.l,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Advance stage primary button
          if (job.stage.next != null) ...[
            KayloButton(
              text: job.stage.actionText(l10n),
              onPressed: () async {
                KayloFeedback.press();
                if (job.stage == JobStage.requested) {
                  await ref.read(jobsRepositoryProvider).acceptJob(job.id);
                } else {
                  await ref.read(jobsRepositoryProvider).advanceJob(job.id);
                }
                if (context.mounted) {
                  final next = job.stage.next;
                  if (next != null) {
                    KayloSnackbar.showSuccess(
                      context,
                      'Status updated to ${next.text(l10n)}',
                    );
                  }
                }
              },
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          // Call customer & chat buttons
          Row(
            children: [
              Expanded(
                child: KayloButton(
                  text: 'Call Customer',
                  icon: Icons.call_rounded,
                  variant: KayloButtonVariant.secondary,
                  onPressed: () => onCall(context, job.customerPhone),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                child: KayloButton(
                  text: 'Chat',
                  icon: Icons.chat_bubble_outline_rounded,
                  variant: KayloButtonVariant.secondary,
                  onPressed: () => KayloSnackbar.showInfo(
                    context,
                    'Chat support will be available here soon',
                  ),
                ),
              ),
            ],
          ),
          if (job.stage != JobStage.inProgress &&
              job.stage != JobStage.cancelled) ...[
            const SizedBox(height: AppSpacing.s),
            KayloButton(
              text: 'Cancel Job',
              variant: KayloButtonVariant.secondary,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel job?'),
                    content: const Text(
                      'Repeated cancellations affect your acceptance rate.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Keep'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Cancel Job',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  KayloFeedback.tap();
                  await ref.read(jobsRepositoryProvider).cancelJob(job.id);
                  if (context.mounted) context.pop();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
