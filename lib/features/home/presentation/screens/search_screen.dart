import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/search_bar_field.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/search_controller.dart';
import '../widgets/voice_search_overlay.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(searchControllerProvider);

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
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.m),
          child: SearchBarField(
            controller: _textController,
            hintText: l10n.searchServicesOrWorkers,
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
        ),
      ),
      body: SafeArea(
        child: searchState.isLoading
            ? ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.l),
                itemCount: 5,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: AppSpacing.m),
                itemBuilder: (context, index) => const ShimmerBox(
                  width: double.infinity,
                  height: 72,
                ),
              )
            : searchState.query.isEmpty
                ? _buildEmptyQueryView(context, ref, searchState, l10n)
                : _buildResultsView(context, ref, searchState, l10n, isDark),
      ),
    );
  }

  Widget _buildEmptyQueryView(
    BuildContext context,
    WidgetRef ref,
    SearchState state,
    AppLocalizations l10n,
  ) {
    final recents = state.recentSearches;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        if (recents.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.recentSearches,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  KayloFeedback.tap();
                  ref
                      .read(searchControllerProvider.notifier)
                      .clearRecentSearches();
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
                  _textController.text = term;
                  ref
                      .read(searchControllerProvider.notifier)
                      .onQueryChanged(term);
                },
                onDeleted: () {
                  KayloFeedback.tap();
                  ref
                      .read(searchControllerProvider.notifier)
                      .removeRecentSearch(term);
                },
                deleteIcon: const Icon(Icons.close, size: 14),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // Trending / Popular Search Suggestions
        Text(
          'Popular Searches',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.m),
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: [
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
                _textController.text = term;
                ref
                    .read(searchControllerProvider.notifier)
                    .onQueryChanged(term);
                ref
                    .read(searchControllerProvider.notifier)
                    .addRecentSearch(term);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsView(
    BuildContext context,
    WidgetRef ref,
    SearchState state,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final services = state.results.services;
    final workers = state.results.workers;

    if (services.isEmpty && workers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: '${l10n.noResultsFound} "${state.query}"',
            description: l10n.tryDifferentSearch,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        // Services Group
        if (services.isNotEmpty) ...[
          Text(
            '${l10n.services} (${services.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          ...services.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: KayloCard(
                onTap: () {
                  KayloFeedback.tap();
                  ref
                      .read(searchControllerProvider.notifier)
                      .addRecentSearch(service.name);
                  context.push(
                    '${Routes.serviceDetails}?id=${service.id}',
                    extra: service,
                  );
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
                      child: const Icon(
                        Icons.handyman_rounded,
                        color: AppColors.brandPrimary,
                        size: 22,
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
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s),
                    Text(
                      '₹${service.basePrice.toInt()}',
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.l),
        ],

        // Professionals Group
        if (workers.isNotEmpty) ...[
          Text(
            '${l10n.professionals} (${workers.length})',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.m),
          ...workers.map((worker) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.m),
              child: KayloCard(
                onTap: () {
                  KayloFeedback.tap();
                  ref
                      .read(searchControllerProvider.notifier)
                      .addRecentSearch(worker.name);
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
                          '₹${(worker.hourlyRate ?? 300).toInt()}/hr',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandPrimary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          worker.location,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
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
