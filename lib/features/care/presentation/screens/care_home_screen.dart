import 'package:flutter/material.dart';

import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// Kaylo Care hub shell (M1). Runs under [AppTheme.careTheme] — larger
/// text, 56x56+ tap targets, high contrast, no glass effects: clarity
/// beats decoration for senior users.
///
/// TODO(M5): replace the coming-soon actions with the real Medicine
/// Reminders, SOS and Care flows. The scaffold, theme and cards are
/// ready to receive them.
class CareHomeScreen extends StatelessWidget {
  const CareHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.careAccent.withOpacity(0.15),
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Emergency SOS gets the most prominent treatment.
                  _SosCard(l10n: l10n),
                  const SizedBox(height: AppSpacing.l),

                  _CareActionCard(
                    icon: Icons.alarm_rounded,
                    color: AppColors.careAccent,
                    title: l10n.medicineReminders,
                    subtitle: l10n.medicineRemindersSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _CareActionCard(
                    icon: Icons.medical_services_rounded,
                    color: AppColors.homeAccent,
                    title: l10n.doctorAppointment,
                    subtitle: l10n.doctorAppointmentSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  _CareActionCard(
                    icon: Icons.volunteer_activism_rounded,
                    color: AppColors.brandPrimary,
                    title: l10n.caregiverBooking,
                    subtitle: l10n.caregiverBookingSubtitle,
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

  const _SosCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        // TODO(M5): trigger the real SOS flow (sos_alerts insert + family
        // notification) instead of the placeholder message.
        onTap: () {
          KayloFeedback.alert();
          KayloSnackbar.showInfo(context, l10n.comingSoon);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.emergencySosSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                    ),
                  ],
                ),
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

  const _CareActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          KayloFeedback.tap();
          KayloSnackbar.showInfo(context, l10n.comingSoon);
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: AppSpacing.l),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
