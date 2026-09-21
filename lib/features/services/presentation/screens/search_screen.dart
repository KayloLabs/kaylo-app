import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/search_bar_field.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/search_providers.dart';
import '../widgets/search_filters_sheet.dart';
import '../widgets/service_card.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final SearchQuery initial;

  const SearchScreen({super.key, this.initial = emptySearch});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial.text);
  late String _text = widget.initial.text;
  late String? _category = widget.initial.category;
  late SearchSort _sort = widget.initial.sort;
  Timer? _debounce;

  SearchQuery get _query => (text: _text, category: _category, sort: _sort);

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) setState(() => _text = value);
    });
  }

  Future<void> _openFilters() async {
    KayloFeedback.tap();
    final result = await showSearchFiltersSheet(
      context,
      current: (category: _category, sort: _sort),
    );
    if (result == null || !mounted) return;
    setState(() {
      _category = result.category;
      _sort = result.sort;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = ref.watch(searchResultsProvider(_query));
    final filtersActive = _category != null || _sort != SearchSort.relevance;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: SearchBarField(
          hintText: l10n.searchServices,
          controller: _controller,
          autofocus: widget.initial.text.isEmpty,
          onChanged: _onChanged,
        ),
        actions: [
          IconButton(
            tooltip: l10n.filters,
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: filtersActive,
              backgroundColor: AppColors.brandPrimary,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.s,
              ),
              children: [
                for (final category in [null, 'home', 'farm', 'care'])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.s),
                    child: ChoiceChip(
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
                        color:
                            isDark ? AppColors.borderDark : AppColors.border,
                      ),
                      onSelected: (_) {
                        KayloFeedback.tap();
                        setState(() => _category = category);
                      },
                    ),
                  ),
                if (_sort != SearchSort.relevance)
                  InputChip(
                    label: Text(sortLabel(l10n, _sort)),
                    avatar: const Icon(Icons.swap_vert_rounded, size: 18),
                    onDeleted: () =>
                        setState(() => _sort = SearchSort.relevance),
                  ),
              ],
            ),
          ),
          Expanded(
            child: results.when(
              data: (list) {
                if (list.isEmpty) {
                  return EmptyState(
                    title: l10n.noResultsTitle,
                    description: l10n.noResultsDescription,
                    icon: Icons.search_off_rounded,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.s,
                    AppSpacing.l,
                    AppSpacing.xxxl,
                  ),
                  itemCount: list.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.m),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        _text.trim().isEmpty
                            ? l10n.allServices
                            : l10n.resultsFor(list.length, _text.trim()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                      );
                    }
                    final service = list[index - 1];
                    return ServiceCard(
                      service: service,
                      onTap: () {
                        KayloFeedback.tap();
                        context.push(Routes.service(service.id));
                      },
                    );
                  },
                );
              },
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.l),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
                itemBuilder: (_, _) => const ShimmerBox(
                  width: double.infinity,
                  height: 112,
                  radius: AppRadius.card,
                ),
              ),
              error: (error, _) => ErrorState(
                title: l10n.somethingWentWrong,
                message: error.toString(),
                onRetry: () => ref.invalidate(searchResultsProvider(_query)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
