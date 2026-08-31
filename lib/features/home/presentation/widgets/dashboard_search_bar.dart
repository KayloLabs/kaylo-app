import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/search_bar_field.dart';
import '../../../../core/widgets/kaylo_liquid_glass.dart';
import '../../../../l10n/generated/app_localizations.dart';
import 'voice_search_overlay.dart';

class DashboardSearchBar extends ConsumerWidget {
  const DashboardSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: KayloLiquidGlass(
            borderRadius: 24.0,
            child: SearchBarField(
              hintText: l10n.searchServices,
              suffix: IconButton(
                tooltip: l10n.voiceSearch,
                icon: const Icon(
                  Icons.mic_none_rounded,
                  color: AppColors.brandPrimary,
                ),
                onPressed: () => showVoiceSearchOverlay(context, ref),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        KayloLiquidGlass(
          borderRadius: 24.0,
          padding: const EdgeInsets.all(AppSpacing.m),
          child: const Icon(
            Icons.tune,
            color: AppColors.brandPrimary,
            size: 24,
          ),
        ),
      ],
    );
  }
}
