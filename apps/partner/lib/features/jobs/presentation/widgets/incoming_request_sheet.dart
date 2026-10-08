import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_core/utils/money.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';

import '../../application/jobs_providers.dart';
import '../../domain/job.dart';
import 'job_map.dart';

class IncomingRequestSheet extends ConsumerStatefulWidget {
  final Job job;

  const IncomingRequestSheet({super.key, required this.job});

  static Future<void> show(BuildContext context, Job job) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IncomingRequestSheet(job: job),
    );
  }

  @override
  ConsumerState<IncomingRequestSheet> createState() =>
      _IncomingRequestSheetState();
}

class _IncomingRequestSheetState extends ConsumerState<IncomingRequestSheet> {
  int _secondsLeft = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) Navigator.of(context).pop();
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _secondsLeft / 30.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.card),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Countdown Ring Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NEW JOB REQUEST',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      color: AppColors.brandPrimary,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                    ),
                  ),
                  Text(
                    '$_secondsLeft',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),

          // Payout Highlight
          Text(
            formatRupees(widget.job.payout),
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.brandPrimary,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Guaranteed Partner Payout',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Job Specs
          Container(
            padding: const EdgeInsets.all(AppSpacing.m),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      size: 20,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      widget.job.serviceName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Text(
                      '${widget.job.distanceKm} km away',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.farmAccent,
                      ),
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.l),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Expanded(
                      child: Text(
                        '${widget.job.customerName} • ${widget.job.addressLine}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.m),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: JobMap(
                    job: widget.job,
                    height: 120,
                    interactive: false,
                    showExpandButton: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Accept / Decline Buttons
          Row(
            children: [
              Expanded(
                child: KayloButton(
                  text: 'Decline',
                  variant: KayloButtonVariant.secondary,
                  onPressed: () {
                    KayloFeedback.tap();
                    ref.read(jobsRepositoryProvider).rejectJob(widget.job.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              Expanded(
                flex: 2,
                child: KayloButton(
                  text: 'Accept Job Now',
                  onPressed: () {
                    KayloFeedback.press();
                    ref.read(jobsRepositoryProvider).acceptJob(widget.job.id);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
