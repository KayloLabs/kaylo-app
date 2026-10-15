import '../../../calls/partner_calls.dart';
import 'package:kaylo_core/network/app_failure.dart';
import '../widgets/job_map.dart';
import '../../../messages/application/messages_providers.dart';
import '../../data/pending_jobs_repository.dart';
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

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/jobs_providers.dart';
import '../../domain/job.dart';
import '../job_stage_text.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({super.key, required this.jobId});

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
          return _JobDetailContent(job: job, isDark: isDark);
        },
        loading: () => const Center(child: KayloLoader()),
        error: (err, _) => Center(
          child: Text(
            err is LiveJobsPending
                ? AppLocalizations.of(context)!.liveJobsPending
                : err.toString(),
          ),
        ),
      ),
      bottomNavigationBar: jobAsync.whenOrNull(
        data: (job) {
          if (job == null) return null;
          return _ActionBar(job: job);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _JobDetailContent extends StatelessWidget {
  final Job job;
  final bool isDark;

  const _JobDetailContent({required this.job, required this.isDark});

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
        if (job.latitude != null && job.longitude != null) ...[
          JobMap(job: job, height: 200),
          const SizedBox(height: AppSpacing.m),
        ],
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
              _DetailRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: job.addressLine,
                multiLine: true,
              ),
              _divider(isDark),
              if (job.distanceKm != null)
                _DetailRow(
                  icon: Icons.near_me_outlined,
                  label: 'Distance',
                  value: '${job.distanceKm} km',
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

class _ActionBar extends ConsumerStatefulWidget {
  final Job job;

  const _ActionBar({required this.job});

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;
  bool _calling = false;
  Job get job => widget.job;

  Future<void> _update(
    Future<void> Function() action, {
    bool cancel = false,
  }) async {
    if (_busy) return;
    final next = job.stage.next;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      if (cancel) {
        context.pop();
      } else if (next != null) {
        final l10n = AppLocalizations.of(context)!;
        KayloSnackbar.showSuccess(
          context,
          l10n.jobStageUpdated(next.text(l10n)),
        );
      }
    } catch (error) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final cashRequired =
          error is AppFailure &&
          error.message.contains('Confirm the cash you collected first');
      KayloSnackbar.showError(
        context,
        cashRequired ? l10n.jobCashRequired : l10n.jobStageUpdateFailed,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _advance() async {
    final repository = ref.read(jobsRepositoryProvider);
    if (job.needsCashCollection) {
      final l10n = AppLocalizations.of(context)!;
      final amount = job.customerPrice;
      if (amount == null || amount <= 0) {
        KayloSnackbar.showError(context, l10n.cashAmountUnavailable);
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.confirmCashReceived),
          content: Text(l10n.confirmCashReceivedBody(formatRupees(amount))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.cashReceived),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await _update(() => repository.markCashCollected(job.id));
      return;
    }
    await _update(
      () => job.isRequested
          ? repository.acceptJob(job.id)
          : repository.advanceJob(job.id),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              text: l10n.chatViewConversation,
              variant: KayloButtonVariant.outline,
              onPressed: () => context.push(Routes.conversation(job.id)),
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
          if (ref.watch(jobsRepositoryProvider).supportsJobActions &&
              job.stage.next != null) ...[
            KayloButton(
              text: job.needsCashCollection
                  ? l10n.confirmCashReceived
                  : job.stage.actionText(l10n),
              isLoading: _busy,
              onPressed: _busy
                  ? null
                  : () {
                      KayloFeedback.press();
                      _advance();
                    },
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          if (!ref.watch(jobsRepositoryProvider).supportsJobActions) ...[
            Text(
              l10n.partnerJobReadOnly,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.s),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 400;
              final width = compact
                  ? (constraints.maxWidth - 8) / 2
                  : (constraints.maxWidth - 16) / 3;
              final unread = ref.watch(partnerThreadUnreadProvider(job.id));
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: width,
                    child: KayloButton(
                      text: l10n.chatCallCustomer,
                      icon: Icons.call_rounded,
                      variant: KayloButtonVariant.secondary,
                      onPressed: !job.isActive || _calling
                          ? null
                          : () async {
                              setState(() => _calling = true);
                              try {
                                await startPartnerBookingCall(
                                  context,
                                  ref,
                                  job.id,
                                );
                              } finally {
                                if (mounted) setState(() => _calling = false);
                              }
                            },
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: Badge.count(
                      count: unread,
                      isLabelVisible: unread > 0,
                      child: KayloButton(
                        text: l10n.chatTitle,
                        icon: Icons.chat_bubble_outline_rounded,
                        variant: KayloButtonVariant.secondary,
                        onPressed: job.isRequested
                            ? null
                            : () => context.push(Routes.conversation(job.id)),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: compact ? constraints.maxWidth : width,
                    child: KayloButton(
                      text: l10n.chatNavigate,
                      icon: Icons.navigation_rounded,
                      variant: KayloButtonVariant.secondary,
                      onPressed:
                          (job.latitude == null || job.longitude == null) &&
                              job.addressLine.trim().isEmpty
                          ? null
                          : () => context.push(Routes.jobMap(job.id)),
                    ),
                  ),
                ],
              );
            },
          ),
          if (ref.watch(jobsRepositoryProvider).supportsJobActions &&
              job.stage != JobStage.inProgress &&
              job.stage != JobStage.cancelled) ...[
            const SizedBox(height: AppSpacing.s),
            KayloButton(
              text: 'Cancel Job',
              variant: KayloButtonVariant.secondary,
              onPressed: _busy
                  ? null
                  : () async {
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
                      if (confirm == true && mounted && !_busy) {
                        KayloFeedback.tap();
                        await _update(
                          () => ref
                              .read(jobsRepositoryProvider)
                              .cancelJob(job.id),
                          cancel: true,
                        );
                      }
                    },
            ),
          ],
        ],
      ),
    );
  }
}
