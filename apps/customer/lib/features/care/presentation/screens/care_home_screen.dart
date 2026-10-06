import 'trusted_contacts_screen.dart';
import 'prescriptions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/care_providers.dart';

/// Kaylo Care hub. Runs under [AppTheme.careTheme] with larger text, 56x56+
/// tap targets, high contrast, no glass effects: clarity beats decoration
/// for senior users.
class CareHomeScreen extends ConsumerWidget {
  const CareHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminders = ref.watch(medicineRemindersProvider).asData?.value;
    final pendingDoses = reminders?.where((r) => !r.isTakenToday).length;

    return Theme(
      data: AppTheme.careTheme,
      child: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            body: SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  120, // clearance for the bottom nav
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    decoration: BoxDecoration(
                      color: AppColors.careAccent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.careAccent.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.careAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.favorite_rounded,
                                color: AppColors.careAccent,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.l),
                            Expanded(
                              child: Text(
                                l10n.kayloCare,
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Text(
                          l10n.careHomeGreeting,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (reminders != null && reminders.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.l),
                          Text(
                            l10n.todaysMedicines,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: AppSpacing.s),
                          Text(
                            l10n.careDosesTaken(
                              reminders.length - pendingDoses!,
                              reminders.length,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.m),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value:
                                  (reminders.length - pendingDoses) /
                                  reminders.length,
                              minHeight: 8,
                              color: AppColors.careAccent,
                              backgroundColor: AppColors.careAccent.withValues(
                                alpha: 0.14,
                              ),
                              semanticsLabel: l10n.todaysMedicines,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Emergency SOS gets the most prominent treatment.
                  _SosCard(
                    l10n: l10n,
                    onTap: () {
                      KayloFeedback.press();
                      context.push(Routes.careSos);
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),

                  _CareActionCard(
                    icon: Icons.document_scanner_outlined,
                    color: AppColors.careAccent,
                    title: l10n.prescriptions,
                    subtitle: l10n.prescriptionsSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PrescriptionsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _CareActionCard(
                    icon: Icons.group_add_outlined,
                    color: AppColors.brandPrimary,
                    title: l10n.trustedContacts,
                    subtitle: l10n.trustedContactsSubtitle,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrustedContactsScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _CareActionCard(
                    icon: Icons.alarm_rounded,
                    color: AppColors.careAccent,
                    title: l10n.medicineReminders,
                    subtitle: l10n.medicineRemindersSubtitle,
                    badge: (pendingDoses ?? 0) > 0
                        ? l10n.pendingDoses(pendingDoses!)
                        : null,
                    onTap: () {
                      KayloFeedback.tap();
                      context.push(Routes.careMedicines);
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _CareActionCard(
                    icon: Icons.medical_services_rounded,
                    color: AppColors.homeAccent,
                    title: l10n.doctorAppointment,
                    subtitle: l10n.doctorAppointmentSubtitle,
                    onTap: () {
                      KayloFeedback.tap();
                      context.push(Routes.doctorAppointment);
                    },
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _CareActionCard(
                    icon: Icons.volunteer_activism_rounded,
                    color: AppColors.brandPrimary,
                    title: l10n.caregiverBooking,
                    subtitle: l10n.caregiverBookingSubtitle,
                    onTap: () {
                      KayloFeedback.tap();
                      context.push(Routes.caregiverBooking);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SosCard extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _SosCard({required this.l10n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.emergencySos,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.emergencySosSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _CareActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.16)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (badge != null) ...[
                      const SizedBox(height: AppSpacing.s),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
