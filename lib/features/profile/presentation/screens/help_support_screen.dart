import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/support_config.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_list_tile.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _mail(BuildContext context, {required String subject, String body = ''}) async {
    final l10n = AppLocalizations.of(context)!;
    KayloFeedback.tap();
    final uri = Uri(
      scheme: 'mailto',
      path: SupportContacts.email,
      query: 'subject=${Uri.encodeComponent(subject)}'
          '&body=${Uri.encodeComponent(body)}',
    );
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      KayloSnackbar.showError(context, l10n.couldNotOpenEmail);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final faqs = [
      (l10n.faqBookQ, l10n.faqBookA),
      (l10n.faqPayQ, l10n.faqPayA),
      (l10n.faqCancelQ, l10n.faqCancelA),
      (l10n.faqWorkersQ, l10n.faqWorkersA),
      (l10n.faqCareQ, l10n.faqCareA),
      (l10n.faqSosQ, l10n.faqSosA),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpSupport)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.m,
          AppSpacing.l,
          140,
        ),
        children: [
          SectionHeader(title: l10n.contactUs),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                KayloListTile(
                  leading: const _Icon(
                      icon: Icons.mail_rounded, color: AppColors.homeAccent),
                  title: Text(l10n.emailUs),
                  subtitle: const Text(SupportContacts.email),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => _mail(context, subject: 'Kaylo support'),
                ),
                Divider(
                  height: 1,
                  indent: AppSpacing.l + 40 + AppSpacing.l,
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
                KayloListTile(
                  leading: const _Icon(
                      icon: Icons.bug_report_rounded, color: AppColors.error),
                  title: Text(l10n.reportProblem),
                  subtitle: Text(l10n.reportProblemSubtitle),
                  trailing: const Icon(Icons.open_in_new_rounded, size: 20),
                  onTap: () => _mail(
                    context,
                    subject: 'Kaylo: problem report',
                    body: '${l10n.reportProblemTemplate}\n\n',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          SectionHeader(title: l10n.faq),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            padding: EdgeInsets.zero,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: [
                  for (final (index, (question, answer)) in faqs.indexed) ...[
                    ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l,
                        vertical: AppSpacing.xs,
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(
                        AppSpacing.l,
                        0,
                        AppSpacing.l,
                        AppSpacing.l,
                      ),
                      iconColor: AppColors.brandPrimary,
                      collapsedIconColor: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                      title: Text(
                        question,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      onExpansionChanged: (_) => KayloFeedback.tap(),
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            answer,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (index < faqs.length - 1)
                      Divider(
                        height: 1,
                        indent: AppSpacing.l,
                        endIndent: AppSpacing.l,
                        color: isDark ? AppColors.borderDark : AppColors.border,
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              l10n.helpFooter,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Icon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _Icon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}
