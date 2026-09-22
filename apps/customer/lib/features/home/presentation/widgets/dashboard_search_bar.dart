import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/search_bar_field.dart';
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/search_controller.dart';
import 'search_filters_sheet.dart';
import 'voice_search_overlay.dart';

class DashboardSearchBar extends ConsumerWidget {
  const DashboardSearchBar({super.key});

  /// The tune button picks a category and order first, then opens the
  /// search screen already narrowed to them.
  Future<void> _openFilters(BuildContext context) async {
    KayloFeedback.tap();
    final filters = await showSearchFiltersSheet(context, current: noFilters);
    if (filters == null || !context.mounted) return;
    context.push(Routes.search, extra: filters);
  }

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
              // The field is a doorway: typing happens on the search
              // screen, where results and filters live.
              readOnly: true,
              onTap: () {
                KayloFeedback.tap();
                context.push(Routes.search);
              },
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _openFilters(context),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Tooltip(
                  message: l10n.filters,
                  child: const Icon(
                    Icons.tune,
                    color: AppColors.brandPrimary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
