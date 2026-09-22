import 'package:flutter/material.dart';

import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/search_controller.dart';

String sortLabel(AppLocalizations l10n, SearchSort sort) => switch (sort) {
      SearchSort.relevance => l10n.sortRelevance,
      SearchSort.priceLowHigh => l10n.sortPriceLowHigh,
      SearchSort.priceHighLow => l10n.sortPriceHighLow,
    };

String categoryLabel(AppLocalizations l10n, String? category) =>
    switch (category) {
      'home' => l10n.home,
      'farm' => l10n.farm,
      'care' => l10n.care,
      _ => l10n.allCategories,
    };

/// Category and sort picker behind the tune button. Resolves with the
/// chosen filters, or null when dismissed.
Future<SearchFilters?> showSearchFiltersSheet(
  BuildContext context, {
  required SearchFilters current,
}) {
  return showModalBottomSheet<SearchFilters>(
    context: context,
    // Over the whole app, not the tab's navigator, so the floating
    // bottom nav does not sit on top of the Apply button.
    useRootNavigator: true,
    useSafeArea: true,
    builder: (context) => _FiltersSheet(current: current),
  );
}

class _FiltersSheet extends StatefulWidget {
  final SearchFilters current;

  const _FiltersSheet({required this.current});

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late String? _category = widget.current.category;
  late SearchSort _sort = widget.current.sort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(fontWeight: FontWeight.w700);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.filters,
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _category = null;
                  _sort = SearchSort.relevance;
                }),
                child: Text(l10n.reset),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(l10n.category, style: labelStyle),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            children: [
              for (final category in [null, 'home', 'farm', 'care'])
                ChoiceChip(
                  label: Text(categoryLabel(l10n, category)),
                  selected: _category == category,
                  showCheckmark: false,
                  selectedColor: AppColors.brandPrimary,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _category == category
                        ? Colors.white
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                  ),
                  shape: const StadiumBorder(),
                  side: BorderSide(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                  onSelected: (_) {
                    KayloFeedback.tap();
                    setState(() => _category = category);
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          Text(l10n.sortBy, style: labelStyle),
          const SizedBox(height: AppSpacing.xs),
          // Hand-rolled radios: RadioListTile's group API changed between
          // the Flutter versions the team runs, and this stays stable.
          for (final sort in SearchSort.values)
            ListTile(
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              leading: Icon(
                _sort == sort
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: _sort == sort
                    ? AppColors.brandPrimary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary),
              ),
              title: Text(sortLabel(l10n, sort)),
              onTap: () {
                KayloFeedback.tap();
                setState(() => _sort = sort);
              },
            ),
          const SizedBox(height: AppSpacing.l),
          KayloButton(
            text: l10n.applyFilters,
            onPressed: () =>
                Navigator.of(context).pop((category: _category, sort: _sort)),
          ),
        ],
      ),
    );
  }
}
