import '../../../reviews/presentation/widgets/review_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/avatar_circle.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/kaylo_chip.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';
import 'package:kaylo_ui/widgets/section_header.dart';

import '../../../../core/router/routes.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/application/partner_session.dart';
import '../../../availability/application/availability_providers.dart';
import '../../../availability/domain/availability.dart';
import '../../../availability/presentation/screens/availability_screen.dart';
import '../../application/profile_providers.dart';
import '../../domain/worker_profile.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/language_tile.dart';

/// The worker's own profile: who they are, how they are doing, what they
/// offer, where the money goes, how far verification has got, and where
/// and when they work. Everything comes from [workerProfileProvider].
class PartnerProfileScreen extends ConsumerWidget {
  const PartnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(workerProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: profileAsync.when(
        loading: () => const Center(child: KayloLoader()),
        error: (e, _) => ErrorState(
          title: l10n.profileLoadFailed,
          message: e is AppFailure ? e.message : '$e',
          onRetry: () => ref.invalidate(workerProfileProvider),
        ),
        data: (profile) => ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.l,
            AppSpacing.m,
            AppSpacing.l,
            100,
          ),
          children: [
            if (profile == null)
              _NotRegistered()
            else
              ..._sections(context, ref, l10n, profile),
            const SizedBox(height: AppSpacing.xl),
            SectionHeader(title: l10n.appSettingsHeader),
            const SizedBox(height: AppSpacing.m),
            const LanguageTile(),
            const SizedBox(height: AppSpacing.xl),
            KayloButton(
              text: l10n.logOut,
              variant: KayloButtonVariant.secondary,
              onPressed: () => _logOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _sections(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    WorkerProfile profile,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final hours = ref.watch(weeklyHoursProvider).asData?.value;

    return [
      // Identity
      KayloCard(
        child: Row(
          children: [
            AvatarCircle(
              imageUrl: profile.photoUrl,
              fallbackText: profile.name,
              radius: 32,
            ),
            const SizedBox(width: AppSpacing.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (profile.isVerified) ...[
                        const SizedBox(width: AppSpacing.s),
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.brandPrimaryBright,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    profile.phone,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: secondary),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  _VerificationChip(status: profile.verification),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.s),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: TextButton.icon(
          onPressed: () => _edit(context, ref, profile),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: Text(l10n.editProfile),
        ),
      ),
      const SizedBox(height: AppSpacing.s),

      // Performance
      SectionHeader(title: l10n.performanceHeader),
      const SizedBox(height: AppSpacing.m),
      KayloCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MetricColumn(
              title: l10n.rating,
              value: profile.rating.toStringAsFixed(1),
              subtitleWidget: Column(
                children: [
                  RatingStars(rating: profile.rating, size: 14),
                  const SizedBox(height: 2),
                  Text(
                    l10n.reviewsCount(profile.reviewsCount),
                    style: TextStyle(fontSize: 11, color: secondary),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 48,
              color: isDark ? Colors.white12 : Colors.black12,
            ),
            _MetricColumn(
              title: l10n.totalJobs,
              value: '${profile.totalJobs}',
              subtitle: l10n.memberSince(_monthYear(context, profile.joinedOn)),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.l),

      const ProfileReviewsSection(),
      const SizedBox(height: AppSpacing.l),

      // Services
      SectionHeader(
        title: l10n.offeredServicesHeader,
        actionText: l10n.editProfile,
        onActionPressed: () => _edit(context, ref, profile),
      ),
      const SizedBox(height: AppSpacing.m),
      KayloCard(
        child: profile.services.isEmpty
            ? Text(
                l10n.noServicesYet,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: secondary),
              )
            : Wrap(
                spacing: AppSpacing.s,
                runSpacing: AppSpacing.s,
                children: [
                  for (final svc in profile.services)
                    KayloChip(
                      label: svc.name,
                      icon: Icons.check_rounded,
                      variant: KayloChipVariant.brand,
                    ),
                ],
              ),
      ),
      const SizedBox(height: AppSpacing.l),

      // Payout
      SectionHeader(title: l10n.payoutHeader),
      const SizedBox(height: AppSpacing.m),
      KayloCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                  child: profile.hasPayoutAccount
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.bankAccount ?? profile.upiId!,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (profile.bankAccount != null &&
                                (profile.upiId ?? '').isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                l10n.upiLabel(profile.upiId!),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: secondary),
                              ),
                            ],
                          ],
                        )
                      : Text(
                          l10n.noPayoutYet,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: secondary),
                        ),
                ),
                TextButton(
                  onPressed: () => _edit(context, ref, profile),
                  child: Text(l10n.editProfile),
                ),
              ],
            ),
            if (profile.bankAccount != null) ...[
              const SizedBox(height: AppSpacing.s),
              Text(
                l10n.bankChangeNote,
                style: TextStyle(fontSize: 11, color: secondary),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.l),

      // Verification
      SectionHeader(title: l10n.verificationHeader),
      const SizedBox(height: AppSpacing.m),
      KayloCard(
        child: Column(
          children: [
            _DocumentRow(
              title: l10n.documentAadhaar,
              status: profile.aadhaarStatus,
            ),
            const Divider(height: 1),
            _DocumentRow(
              title: l10n.documentPoliceCertificate,
              status: profile.documentStatus('police_certificate'),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.l),

      // Service area and schedule
      SectionHeader(title: l10n.areaScheduleHeader),
      const SizedBox(height: AppSpacing.m),
      KayloCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: AppColors.farmAccent,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    [
                      profile.district ?? l10n.noDistrictYet,
                      l10n.travelRadius(_km(profile.travelRadiusKm)),
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 20,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Text(
                    _scheduleSummary(context, l10n, hours, profile),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: secondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.m),
            KayloButton(
              text: l10n.manageAvailability,
              icon: Icons.edit_calendar_outlined,
              variant: KayloButtonVariant.outline,
              onPressed: () {
                KayloFeedback.tap();
                context.push(Routes.availability);
              },
            ),
          ],
        ),
      ),
    ];
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    WorkerProfile profile,
  ) async {
    KayloFeedback.tap();
    final saved = await showEditProfileSheet(context, profile);
    if (saved && context.mounted) {
      KayloSnackbar.showSuccess(
        context,
        AppLocalizations.of(context)!.profileSaved,
      );
    }
  }

  Future<void> _logOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logOutTitle),
        content: Text(l10n.logOutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.logOut,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      KayloFeedback.press();
      await ref.read(partnerAuthRepositoryProvider).signOut();
      if (context.mounted) context.go(Routes.login);
    }
  }

  static String _km(double km) =>
      km == km.roundToDouble() ? km.toInt().toString() : km.toStringAsFixed(1);

  static String _monthYear(BuildContext context, DateTime date) {
    final locale = Localizations.localeOf(context).toString();
    try {
      return DateFormat.yMMM(locale).format(date);
    } catch (_) {
      return DateFormat.yMMM('en').format(date);
    }
  }

  /// "Mon – Sat · 8:00 AM – 7:00 PM" when every working day shares one
  /// window; otherwise a note that the days differ. Falls back to the free
  /// text typed at registration until hours are saved.
  static String _scheduleSummary(
    BuildContext context,
    AppLocalizations l10n,
    WeeklyHours? hours,
    WorkerProfile profile,
  ) {
    if (hours == null) {
      final note = (profile.workingHoursNote ?? '').trim();
      return note.isEmpty ? l10n.hoursNotSet : note;
    }
    final working = hours.workingDays;
    if (working.isEmpty) return l10n.hoursNotSet;
    if (!hours.hasOneWindow) return l10n.customHours;
    final first = working.first.weekday;
    final last = working.last.weekday;
    final consecutive = last - first + 1 == working.length;
    final days = consecutive
        ? (working.length == 1
              ? weekdayName(context, first, short: true)
              : '${weekdayName(context, first, short: true)} – '
                    '${weekdayName(context, last, short: true)}')
        : working
              .map((d) => weekdayName(context, d.weekday, short: true))
              .join(', ');
    return '$days · ${formatMinutes(context, working.first.startMinutes)} – '
        '${formatMinutes(context, working.first.endMinutes)}';
  }
}

class _NotRegistered extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return KayloCard(
      child: EmptyState(
        icon: Icons.badge_outlined,
        title: l10n.notRegisteredTitle,
        description: l10n.notRegisteredBody,
      ),
    );
  }
}

class _VerificationChip extends StatelessWidget {
  final VerificationStatus status;

  const _VerificationChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (status) {
      VerificationStatus.verified => KayloChip(
        label: l10n.verifiedPartner,
        icon: Icons.shield_rounded,
        variant: KayloChipVariant.success,
      ),
      VerificationStatus.underReview => KayloChip(
        label: l10n.verificationUnderReview,
        icon: Icons.hourglass_top_rounded,
        variant: KayloChipVariant.warning,
      ),
      VerificationStatus.rejected => KayloChip(
        label: l10n.verificationRejected,
        icon: Icons.error_outline_rounded,
        variant: KayloChipVariant.error,
      ),
      VerificationStatus.unverified => KayloChip(
        label: l10n.verificationNotStarted,
        icon: Icons.shield_outlined,
        variant: KayloChipVariant.neutral,
      ),
    };
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
    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

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
            color: secondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        if (subtitleWidget != null)
          subtitleWidget!
        else if (subtitle != null)
          Text(subtitle!, style: TextStyle(fontSize: 11, color: secondary)),
      ],
    );
  }
}

class _DocumentRow extends StatelessWidget {
  final String title;
  final DocumentStatus? status;

  const _DocumentRow({required this.title, required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (label, icon, variant) = switch (status) {
      DocumentStatus.verified => (
        l10n.statusVerified,
        Icons.check_circle_rounded,
        KayloChipVariant.success,
      ),
      DocumentStatus.pending => (
        l10n.statusPending,
        Icons.hourglass_top,
        KayloChipVariant.warning,
      ),
      DocumentStatus.rejected => (
        l10n.statusRejected,
        Icons.error_outline_rounded,
        KayloChipVariant.error,
      ),
      null => (
        l10n.statusNotSubmitted,
        Icons.upload_file_outlined,
        KayloChipVariant.neutral,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          KayloChip(label: label, icon: icon, variant: variant),
        ],
      ),
    );
  }
}
