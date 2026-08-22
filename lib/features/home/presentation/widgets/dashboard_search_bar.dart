import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/search_bar_field.dart';
import '../../../../core/widgets/kaylo_liquid_glass.dart';
import '../../../../l10n/generated/app_localizations.dart';

class DashboardSearchBar extends StatelessWidget {
  const DashboardSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    
    return Row(
      children: [
        Expanded(
          child: KayloLiquidGlass(
            borderRadius: 24.0,
            child: SearchBarField(
              hintText: AppLocalizations.of(context)!.searchServices,
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
