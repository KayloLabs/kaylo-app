import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_chip.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';
import 'package:kaylo_ui/widgets/section_header.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/partner_session.dart';
import '../widgets/language_tile.dart';

class PartnerProfileScreen extends ConsumerWidget {
  const PartnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final worker = ref.watch(partnerWorkerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          100,
        ),
        children: [
          // Identity Card
          KayloCard(
            child: Row(
              children: [
                AvatarCircle(fallbackText: worker.name, radius: 32),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              worker.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          const Icon(
                            Icons.verified_rounded,
                            color: AppColors.brandPrimaryBright,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        worker.phone,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s),
                      const KayloChip(
                        label: 'Verified Partner',
                        icon: Icons.shield_rounded,
                        variant: KayloChipVariant.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Performance Strip
          const SectionHeader(title: 'Performance & Ratings'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      title: 'Rating',
                      value: '${worker.rating}',
                      subtitleWidget: RatingStars(
                        rating: worker.rating,
                        size: 14,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    _MetricColumn(
                      title: 'Total Jobs',
                      value: '${worker.totalJobs}',
                      subtitle: 'Kannur District',
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MetricColumn(
                      title: 'Acceptance',
                      value: '${worker.acceptanceRate}%',
                      subtitle: 'Top 5% Partner',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                    _MetricColumn(
                      title: 'Completion',
                      value: '${worker.completionRate}%',
                      subtitle: '99% on-time',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Skills & Services
          const SectionHeader(title: 'Offered Services'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final svc in worker.services)
                  KayloChip(
                    label: svc,
                    icon: Icons.check_rounded,
                    variant: KayloChipVariant.brand,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Payout Details
          const SectionHeader(title: 'Bank & Payout Account'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
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
                    Icons.account_balance_rounded,
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
                        worker.bankAccount,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'UPI ID: ${worker.upiId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    KayloFeedback.tap();
                    KayloSnackbar.showInfo(
                      context,
                      'Bank account changes require support verification',
                    );
                  },
                  child: const Text('Edit'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Verification & Documents
          const SectionHeader(title: 'KYC & Verification Status'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Column(
              children: [
                _VerificationRow(
                  title: 'Aadhaar Card (UIDAI)',
                  subtitle: 'Verified by Kaylo Trust Team',
                  isVerified: worker.aadhaarVerified,
                ),
                const Divider(height: 1),
                _VerificationRow(
                  title: 'Police Clearance Certificate',
                  subtitle: 'Kerala Police Background Check Passed',
                  isVerified: worker.policeVerified,
                ),
                const Divider(height: 1),
                const _VerificationRow(
                  title: 'Partner ID Badge',
                  subtitle: 'KYL-88219 (Active License)',
                  isVerified: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Availability
          const SectionHeader(title: 'Service Area & Schedule'),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 20,
                      color: AppColors.brandPrimary,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      worker.workingHours,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 20,
                      color: AppColors.farmAccent,
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      worker.district,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          SectionHeader(
            title: AppLocalizations.of(context)?.appSettingsHeader ?? 'App Settings',
          ),
          const SizedBox(height: AppSpacing.m),
          const LanguageTile(),
          const SizedBox(height: AppSpacing.xl),

          // Log out
          KayloButton(
            text: 'Log out of Partner App',
            variant: KayloButtonVariant.secondary,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text(
                    'You will need to sign in again with your phone number to receive jobs.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text(
                        'Log out',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                KayloFeedback.press();
                await ref.read(partnerAuthRepositoryProvider).signOut();
                if (context.mounted) {
                  context.go(Routes.login);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _MetricColumn extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget? subtitleWidget;

  const _MetricColumn({
    required this.title,
    required this.value,
    this.subtitle,
    this.subtitleWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (subtitleWidget != null)
          subtitleWidget!
        else if (subtitle != null)
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}

class _VerificationRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isVerified;

  const _VerificationRow({
    required this.title,
    required this.subtitle,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          KayloChip(
            label: isVerified ? 'Verified' : 'Pending',
            icon: isVerified ? Icons.check_circle_rounded : Icons.hourglass_top,
            variant: isVerified
                ? KayloChipVariant.success
                : KayloChipVariant.warning,
          ),
        ],
      ),
    );
  }
}
