import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/router/service_routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/search_bar_field.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/search_controller.dart';
import '../widgets/search_filters_sheet.dart';
import '../widgets/voice_search_overlay.dart';

/// Text search over services and professionals. Typing runs a debounced
/// query; the chips and the tune button narrow it by category and order,
/// and a category on its own browses everything in it.
class SearchScreen extends ConsumerStatefulWidget {
  /// Query to run on open (the hero banner deep-links here).
  final String initialQuery;

  /// Filters to start with (the dashboard's tune button picks them).
  final SearchFilters? initialFilters;

  const SearchScreen({super.key, this.initialQuery = '', this.initialFilters});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.initialQuery,
  );

  @override
  void initState() {
    super.initState();
    if (widget.initialFilters == null && widget.initialQuery.isEmpty) return;
    // Providers cannot change while the first frame builds.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(searchControllerProvider.notifier);
      final filters = widget.initialFilters;
      if (filters != null) notifier.setFilters(filters);
      if (widget.initialQuery.isNotEmpty) {
        notifier.onQueryChanged(widget.initialQuery);
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _search(String term) {
    _textController.text = term;
    _textController.selection = TextSelection.collapsed(offset: term.length);
    ref.read(searchControllerProvider.notifier).onQueryChanged(term);
  }

  Future<void> _openFilters() async {
    KayloFeedback.tap();
    final result = await showSearchFiltersSheet(
      context,
      current: ref.read(searchControllerProvider).filters,
    );
    if (result == null || !mounted) return;
    ref.read(searchControllerProvider.notifier).setFilters(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(searchControllerProvider);
    final active = filtersActive(searchState.filters);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            KayloFeedback.tap();
            context.pop();
          },
        ),
        title: SearchBarField(
          controller: _textController,
          hintText: l10n.searchServicesOrWorkers,
          autofocus:
              widget.initialQuery.isEmpty && widget.initialFilters == null,
          onChanged: (val) {
            ref.read(searchControllerProvider.notifier).onQueryChanged(val);
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
        actions: [
          IconButton(
            tooltip: l10n.filters,
            onPressed: _openFilters,
            icon: Badge(
              isLabelVisible: active,
              backgroundColor: AppColors.brandPrimary,
              smallSize: 8,
              child: const Icon(Icons.tune),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _FilterChips(filters: searchState.filters),
            Expanded(
              child: searchState.isLoading
                  ? ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      itemCount: 5,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.m),
                      itemBuilder: (context, index) => const ShimmerBox(
                        width: double.infinity,
                        height: 72,
                        radius: AppRadius.card,
                      ),
                    )
                  : searchState.hasQuery
                  ? _buildResultsView(context, searchState, l10n, isDark)
                  : _buildEmptyQueryView(context, searchState, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueryView(
    BuildContext context,
    SearchState state,
    AppLocalizations l10n,
  ) {
    final recents = state.recentSearches;
    final notifier = ref.read(searchControllerProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        if (recents.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentSearches,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  KayloFeedback.tap();
                  notifier.clearRecentSearches();
                },
                child: Text(
                  l10n.clearAll,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s),
          Wrap(
            spacing: AppSpacing.s,
            runSpacing: AppSpacing.s,
            children: recents.map((term) {
              return InputChip(
                label: Text(term),
                onPressed: () {
                  KayloFeedback.tap();
                  _search(term);
                },
                onDeleted: () {
                  KayloFeedback.tap();
                  notifier.removeRecentSearch(term);
                },
                deleteIcon: const Icon(Icons.close, size: 14),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text(
          l10n.popularSearches,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children:
              [
                'Plumbing',
                'Electrical',
                'House Cleaning',
                'AC Service',
                'Carpentry',
                'Caregiver',
                'Painting',
              ].map((term) {
                return ActionChip(
                  avatar: const Icon(Icons.trending_up_rounded, size: 16),
                  label: Text(term),
                  onPressed: () {
                    KayloFeedback.tap();
                    _search(term);
                    notifier.addRecentSearch(term);
                  },
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsView(
    BuildContext context,
    SearchState state,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final services = state.results.services;
    final workers = state.results.workers;
    final query = state.query.trim();
    final notifier = ref.read(searchControllerProvider.notifier);

    if (services.isEmpty && workers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: query.isEmpty
                ? l10n.noResultsTitle
                : '${l10n.noResultsFound} "$query"',
            description: l10n.noResultsDescription,
            icon: Icons.search_off_rounded,
          ),
        ),
      );
    }

    final secondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        if (services.isNotEmpty) ...[
          Text(
            '${l10n.services} (${services.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          ...services.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: KayloCard(
                onTap: () {
                  KayloFeedback.tap();
                  notifier.addRecentSearch(service.name);
                  openService(GoRouter.of(context), service);
                },
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceTintDark
                            : AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      child: service.iconPath.isEmpty
                          ? const Icon(
                              Icons.handyman_rounded,
                              color: AppColors.brandPrimary,
                              size: 22,
                            )
                          : Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.asset(service.iconPath),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            service.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: secondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      formatRupees(service.basePrice),
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: secondary),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.l),
        ],
        if (workers.isNotEmpty) ...[
          Text(
            '${l10n.professionals} (${workers.length})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          ...workers.map((worker) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: KayloCard(
                onTap: () {
                  KayloFeedback.tap();
                  notifier.addRecentSearch(worker.name);
                  context.push(
                    '${Routes.workerProfile}?workerId=${worker.id}',
                    extra: worker,
                  );
                },
                padding: const EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    AvatarCircle(
                      imageUrl: worker.profileImageUrl,
                      fallbackText: worker.name,
                      radius: 24,
                    ),
                    const SizedBox(width: AppSpacing.m),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  worker.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (worker.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.brandPrimary,
                                  size: 15,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          RatingStars(
                            rating: worker.rating,
                            reviewCount: worker.reviewsCount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${formatRupees(worker.hourlyRate ?? 300)}/hr',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          worker.location,
                          style: TextStyle(fontSize: 11, color: secondary),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: secondary),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

/// Category chips plus a removable sort chip, mirroring the tune sheet so
/// the active narrowing is always visible above the results.
class _FilterChips extends ConsumerWidget {
  final SearchFilters filters;

  const _FilterChips({required this.filters});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final notifier = ref.read(searchControllerProvider.notifier);

    return SizedBox(
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
                selected: filters.category == category,
                showCheckmark: false,
                selectedColor: AppColors.brandPrimary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: filters.category == category
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
                  notifier.setFilters((category: category, sort: filters.sort));
                },
              ),
            ),
          if (filters.sort != SearchSort.relevance)
            InputChip(
              label: Text(sortLabel(l10n, filters.sort)),
              avatar: const Icon(Icons.swap_vert_rounded, size: 18),
              onDeleted: () {
                KayloFeedback.tap();
                notifier.setFilters((
                  category: filters.category,
                  sort: SearchSort.relevance,
                ));
              },
            ),
        ],
      ),
    );
  }
}
