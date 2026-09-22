import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/worker.dart';
import '../../../home/application/user_location_provider.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/workers_providers.dart';

class WorkerListScreen extends ConsumerWidget {
  final String serviceId;
  final String? serviceName;

  const WorkerListScreen({
    super.key,
    required this.serviceId,
    this.serviceName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeLocation = ref.watch(userLocationProvider).label;
    final filterSortState = ref.watch(workerFilterSortProvider);
    final workersAsync = ref.watch(filteredWorkersProvider(serviceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              serviceName ?? l10n.availableWorkers,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 13,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 3),
                Text(
                  activeLocation,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            KayloFeedback.tap();
            context.pop();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Sort & Filter Controls Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.s,
              ),
              child: Row(
                children: [
                  // Sort button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.sort_rounded, size: 18),
                      label: Text(
                        _getSortLabel(filterSortState.sort, l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.m,
                          vertical: AppSpacing.s,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                      onPressed: () {
                        KayloFeedback.tap();
                        _showSortBottomSheet(context, ref, l10n);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.m),

                  // Filter button
                  OutlinedButton.icon(
                    icon: Badge(
                      isLabelVisible: filterSortState.filter.hasActiveFilters,
                      child: const Icon(Icons.tune_rounded, size: 18),
                    ),
                    label: Text(
                      l10n.filter,
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: AppSpacing.s,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      side: BorderSide(
                        color: filterSortState.filter.hasActiveFilters
                            ? AppColors.brandPrimary
                            : (isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300),
                      ),
                    ),
                    onPressed: () {
                      KayloFeedback.tap();
                      _showFilterBottomSheet(context, ref, l10n);
                    },
                  ),
                ],
              ),
            ),

            // Active Filters Chips (if any)
            if (filterSortState.filter.hasActiveFilters)
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.l),
                  children: [
                    if (filterSortState.filter.minRating != null)
                      _buildActiveFilterChip(
                        label: '★ ${filterSortState.filter.minRating}+',
                        onDeleted: () {
                          ref.read(workerFilterSortProvider.notifier).updateFilter(
                                filterSortState.filter.copyWith(minRating: null),
                              );
                        },
                      ),
                    if (filterSortState.filter.maxPrice != null)
                      _buildActiveFilterChip(
                        label: '≤ ₹${filterSortState.filter.maxPrice!.toInt()}',
                        onDeleted: () {
                          ref.read(workerFilterSortProvider.notifier).updateFilter(
                                filterSortState.filter.copyWith(maxPrice: null),
                              );
                        },
                      ),
                    if (filterSortState.filter.availableToday)
                      _buildActiveFilterChip(
                        label: l10n.availableToday,
                        onDeleted: () {
                          ref.read(workerFilterSortProvider.notifier).updateFilter(
                                filterSortState.filter.copyWith(availableToday: false),
                              );
                        },
                      ),
                    if (filterSortState.filter.verifiedOnly)
                      _buildActiveFilterChip(
                        label: l10n.verifiedOnly,
                        onDeleted: () {
                          ref.read(workerFilterSortProvider.notifier).updateFilter(
                                filterSortState.filter.copyWith(verifiedOnly: false),
                              );
                        },
                      ),
                    TextButton(
                      onPressed: () {
                        KayloFeedback.tap();
                        ref.read(workerFilterSortProvider.notifier).resetFilter();
                      },
                      child: Text(l10n.reset, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // Workers List
            Expanded(
              child: workersAsync.when(
                data: (workers) {
                  if (workers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            EmptyState(
                              title: l10n.noWorkersFound,
                              description: l10n.tryDifferentSearch,
                            ),
                            const SizedBox(height: AppSpacing.m),
                            if (filterSortState.filter.hasActiveFilters)
                              KayloButton(
                                text: l10n.reset,
                                variant: KayloButtonVariant.outline,
                                onPressed: () {
                                  KayloFeedback.tap();
                                  ref
                                      .read(workerFilterSortProvider.notifier)
                                      .resetFilter();
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    itemCount: workers.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppSpacing.m),
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      return _WorkerCardRow(
                        worker: worker,
                        serviceId: serviceId,
                      );
                    },
                  );
                },
                loading: () => ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.l),
                  itemCount: 4,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.m),
                  itemBuilder: (context, index) => const ShimmerBox(
                    width: double.infinity,
                    height: 120,
                  ),
                ),
                error: (err, stack) => ErrorState(
                  message: err.toString(),
                  onRetry: () =>
                      ref.invalidate(filteredWorkersProvider(serviceId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.s),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 14),
        onDeleted: () {
          KayloFeedback.tap();
          onDeleted();
        },
        padding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  String _getSortLabel(WorkerSort sort, AppLocalizations l10n) {
    switch (sort) {
      case WorkerSort.rating:
        return '${l10n.sortBy}: ${l10n.rating}';
      case WorkerSort.priceLowToHigh:
        return '${l10n.sortBy}: ${l10n.priceLowToHigh}';
      case WorkerSort.priceHighToLow:
        return '${l10n.sortBy}: ${l10n.priceHighToLow}';
      case WorkerSort.experience:
        return '${l10n.sortBy}: ${l10n.experience}';
      case WorkerSort.distance:
        return '${l10n.sortBy}: ${l10n.distance}';
    }
  }

  void _showSortBottomSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final currentSort = ref.read(workerFilterSortProvider).sort;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Text(
                  l10n.sortBy,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              RadioGroup<WorkerSort>(
                groupValue: currentSort,
                onChanged: (val) {
                  KayloFeedback.tap();
                  if (val != null) {
                    ref.read(workerFilterSortProvider.notifier).setSort(val);
                  }
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    RadioListTile<WorkerSort>(
                      title: Text(l10n.rating),
                      value: WorkerSort.rating,
                    ),
                    RadioListTile<WorkerSort>(
                      title: Text(l10n.priceLowToHigh),
                      value: WorkerSort.priceLowToHigh,
                    ),
                    RadioListTile<WorkerSort>(
                      title: Text(l10n.priceHighToLow),
                      value: WorkerSort.priceHighToLow,
                    ),
                    RadioListTile<WorkerSort>(
                      title: Text(l10n.experience),
                      value: WorkerSort.experience,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.m),
            ],
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final currentFilter = ref.read(workerFilterSortProvider).filter;
    double? tempMinRating = currentFilter.minRating;
    double? tempMaxPrice = currentFilter.maxPrice;
    bool tempAvailableToday = currentFilter.availableToday;
    bool tempVerifiedOnly = currentFilter.verifiedOnly;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.filter,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {
                            KayloFeedback.tap();
                            setModalState(() {
                              tempMinRating = null;
                              tempMaxPrice = null;
                              tempAvailableToday = false;
                              tempVerifiedOnly = false;
                            });
                          },
                          child: Text(l10n.reset),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: AppSpacing.s),

                    // Min Rating
                    Text(
                      l10n.minRating,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.s),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('★ 4.0+'),
                          selected: tempMinRating == 4.0,
                          onSelected: (selected) {
                            setModalState(() {
                              tempMinRating = selected ? 4.0 : null;
                            });
                          },
                        ),
                        const SizedBox(width: AppSpacing.s),
                        ChoiceChip(
                          label: const Text('★ 4.5+'),
                          selected: tempMinRating == 4.5,
                          onSelected: (selected) {
                            setModalState(() {
                              tempMinRating = selected ? 4.5 : null;
                            });
                          },
                        ),
                        const SizedBox(width: AppSpacing.s),
                        ChoiceChip(
                          label: const Text('★ 4.8+'),
                          selected: tempMinRating == 4.8,
                          onSelected: (selected) {
                            setModalState(() {
                              tempMinRating = selected ? 4.8 : null;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Max Price
                    Text(
                      '${l10n.priceRange} (≤ ₹${(tempMaxPrice ?? 600).toInt()}/hr)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Slider(
                      value: tempMaxPrice ?? 600,
                      min: 200,
                      max: 600,
                      divisions: 8,
                      label: '₹${(tempMaxPrice ?? 600).toInt()}',
                      onChanged: (val) {
                        setModalState(() {
                          tempMaxPrice = val;
                        });
                      },
                    ),
                    const SizedBox(height: AppSpacing.m),

                    // Available Today Switch
                    SwitchListTile(
                      title: Text(l10n.availableToday),
                      value: tempAvailableToday,
                      onChanged: (val) {
                        setModalState(() {
                          tempAvailableToday = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),

                    // Verified Only Switch
                    SwitchListTile(
                      title: Text(l10n.verifiedOnly),
                      value: tempVerifiedOnly,
                      onChanged: (val) {
                        setModalState(() {
                          tempVerifiedOnly = val;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: AppSpacing.l),

                    // Apply Button
                    KayloButton(
                      text: l10n.apply,
                      onPressed: () {
                        KayloFeedback.press();
                        ref
                            .read(workerFilterSortProvider.notifier)
                            .updateFilter(
                              WorkerFilter(
                                minRating: tempMinRating,
                                maxPrice: tempMaxPrice,
                                availableToday: tempAvailableToday,
                                verifiedOnly: tempVerifiedOnly,
                              ),
                            );
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _WorkerCardRow extends StatelessWidget {
  final Worker worker;
  final String serviceId;

  const _WorkerCardRow({
    required this.worker,
    required this.serviceId,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return KayloCard(
      onTap: () {
        KayloFeedback.tap();
        context.push(
          '${Routes.workerProfile}?workerId=${worker.id}&serviceId=$serviceId',
          extra: worker,
        );
      },
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AvatarCircle(
                imageUrl: worker.profileImageUrl,
                fallbackText: worker.name,
                radius: 28,
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
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (worker.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.brandPrimary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      worker.location,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    RatingStars(
                      rating: worker.rating,
                      reviewCount: worker.reviewsCount,
                    ),
                  ],
                ),
              ),
              // Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${(worker.hourlyRate ?? 300).toInt()}/hr',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${worker.trustScore.toInt()}% Trust',
                      style: const TextStyle(
                        color: AppColors.brandPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.s),

          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${worker.totalJobs} ${l10n.completedJobs}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      KayloFeedback.tap();
                      context.push(
                        '${Routes.workerProfile}?workerId=${worker.id}&serviceId=$serviceId',
                        extra: worker,
                      );
                    },
                    child: Text(
                      l10n.workerProfile,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.button),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.m,
                        vertical: 6,
                      ),
                      minimumSize: const Size(80, 34),
                    ),
                    onPressed: () {
                      KayloFeedback.press();
                      // M4 Handoff Contract: {serviceId, workerId}
                      context.push(
                        '${Routes.bookService}?serviceId=$serviceId&workerId=${worker.id}',
                        extra: {
                          'serviceId': serviceId,
                          'workerId': worker.id,
                          'worker': worker,
                        },
                      );
                    },
                    child: Text(
                      l10n.bookNow,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
