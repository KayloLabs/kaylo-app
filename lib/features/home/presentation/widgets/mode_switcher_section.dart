import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/kaylo_liquid_glass.dart';
import '../../../../l10n/generated/app_localizations.dart';

class ModeSwitcherSection extends StatelessWidget {
  const ModeSwitcherSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: AppLocalizations.of(context)!.whatDoYouNeedHelpWith,
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _ModeCard(
                title: AppLocalizations.of(context)!.home,
                subtitle: AppLocalizations.of(context)!.homeSubtitle,
                imagePath: 'assets_kaylo/3d_transparent/mode_home.png',
                colorOverlay: Colors.amber.withValues(alpha: 0.15), // Gold tint
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: _ModeCard(
                title: AppLocalizations.of(context)!.farm,
                subtitle: AppLocalizations.of(context)!.farmSubtitle,
                imagePath: 'assets_kaylo/3d_transparent/mode_farm.png',
                colorOverlay: Colors.green.withValues(alpha: 0.15), // Green tint
                onTap: () {},
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: _ModeCard(
                title: AppLocalizations.of(context)!.care,
                subtitle: AppLocalizations.of(context)!.careSubtitle,
                imagePath: 'assets_kaylo/3d_transparent/mode_care.png',
                colorOverlay: Colors.deepPurpleAccent.withValues(alpha: 0.15), // Violet tint
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;
  final Color? colorOverlay;

  const _ModeCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
    this.colorOverlay,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return KayloLiquidGlass(
      borderRadius: AppRadius.card,
      colorOverlay: colorOverlay,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    imagePath,
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.brandPrimaryDark,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.2,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
