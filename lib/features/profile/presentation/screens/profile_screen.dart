import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_liquid_glass.dart';
import '../../../../core/widgets/kaylo_list_tile.dart';
import '../../../../core/widgets/kaylo_snackbar.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';

import '../../../auth/application/session_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessionState = ref.watch(sessionControllerProvider);
    final user = sessionState.whenOrNull(data: (u) => u);
    final l10n = AppLocalizations.of(context)!;
    
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
              child: Text(
                l10n.profile,
                style: Theme.of(context).textTheme.displaySmall,
              ),
            ),

            // Identity card on a soft brand gradient, glass on top.
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          AppColors.brandPrimaryDark.withValues(alpha: 0.45),
                          AppColors.surfaceDark,
                        ]
                      : [
                          AppColors.brandPrimaryBright.withValues(alpha: 0.25),
                          AppColors.surfaceTint,
                        ],
                ),
              ),
              child: KayloLiquidGlass(
                borderRadius: 28,
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    AvatarCircle(
                      fallbackText: '${user.firstName} ${user.lastName}'.trim(),
                      radius: 34,
                    ),
                    const SizedBox(width: AppSpacing.l),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${user.firstName} ${user.lastName}'.trim(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            user.phone,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          KayloSnackbar.showInfo(context, l10n.profileEditSoon),
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.l),

            // Quick stats
            Row(
              children: [
                Expanded(
                    child: _StatTile(
                        value: '12',
                        label: l10n.statBookings,
                        icon: Icons.event_available_rounded)),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                    child: _StatTile(
                        value: '4.9',
                        label: l10n.statRating,
                        icon: Icons.star_rounded)),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                    child: _StatTile(
                        value: '5',
                        label: l10n.statSaved,
                        icon: Icons.bookmark_rounded)),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: l10n.account),
            const SizedBox(height: AppSpacing.m),
            KayloCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.homeAccent,
                    title: l10n.myBookings,
                    subtitle: l10n.myBookingsSubtitle,
                    onTap: () => context.go(Routes.bookings),
                  ),
                  _tileDivider(isDark),
                  _MenuTile(
                    icon: Icons.location_on_rounded,
                    color: AppColors.farmAccent,
                    title: l10n.savedAddresses,
                    onTap: () =>
                        KayloSnackbar.showInfo(context, l10n.comingSoon),
                  ),
                  _tileDivider(isDark),
                  _MenuTile(
                    icon: Icons.account_balance_wallet_rounded,
                    color: AppColors.careAccent,
                    title: l10n.paymentMethods,
                    onTap: () =>
                        KayloSnackbar.showInfo(context, l10n.comingSoon),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: l10n.preferences),
            const SizedBox(height: AppSpacing.m),
            KayloCard(
              padding: EdgeInsets.zero,
              child: _MenuTile(
                icon: Icons.settings_rounded,
                color: AppColors.textSecondary,
                title: l10n.settings,
                subtitle: l10n.settingsSubtitle,
                onTap: () =>
                    context.go('${Routes.profile}/${Routes.settings}'),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            SectionHeader(title: l10n.support),
            const SizedBox(height: AppSpacing.m),
            KayloCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.help_rounded,
                    color: AppColors.secondaryAccent,
                    title: l10n.helpSupport,
                    onTap: () =>
                        KayloSnackbar.showInfo(context, l10n.comingSoon),
                  ),
                  _tileDivider(isDark),
                  _MenuTile(
                    icon: Icons.favorite_rounded,
                    color: AppColors.error,
                    title: l10n.rateKaylo,
                    onTap: () =>
                        KayloSnackbar.showInfo(context, l10n.rateThanks),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Logout
            KayloCard(
              padding: EdgeInsets.zero,
              child: _MenuTile(
                icon: Icons.logout_rounded,
                color: AppColors.error,
                title: l10n.logOut,
                titleColor: AppColors.error,
                onTap: () => _confirmLogout(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.xxxl),
          ],
        ),
      ),
    );
  }

  Widget _tileDivider(bool isDark) => Divider(
        height: 1,
        indent: AppSpacing.l + 40 + AppSpacing.l,
        color: isDark ? AppColors.borderDark : AppColors.border,
      );

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logOutConfirmTitle),
        content: Text(l10n.logOutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.logOut),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await ref.read(sessionControllerProvider.notifier).signOut();
    if (context.mounted) context.go(Routes.login);
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatTile({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return KayloCard(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.l, horizontal: AppSpacing.s),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brandPrimary, size: 20),
          const SizedBox(height: AppSpacing.s),
          Text(value, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback? onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.titleColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return KayloListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        title,
        style: titleColor != null ? TextStyle(color: titleColor) : null,
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
