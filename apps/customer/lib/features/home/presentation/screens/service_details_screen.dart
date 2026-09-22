import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaylo_core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_card.dart';
import 'package:kaylo_ui/widgets/rating_stars.dart';
import 'package:kaylo_ui/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/home_providers.dart';

class ServiceDetailsScreen extends ConsumerStatefulWidget {
  final String serviceId;
  final ServiceItem? initialService;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceId,
    this.initialService,
  });

  @override
  ConsumerState<ServiceDetailsScreen> createState() =>
      _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends ConsumerState<ServiceDetailsScreen> {
  final Set<String> _selectedSubServices = {};

  List<String> _getSubServicesFor(String serviceName) {
    final lower = serviceName.toLowerCase();
    if (lower.contains('plumb')) {
      return ['Tap Repair', 'Pipe Leakage', 'Drain Cleaning', 'Installation'];
    }
    if (lower.contains('electric')) {
      return [
        'Switchboard Repair',
        'Wiring Fix',
        'Fan Installation',
        'MCB Tripping',
      ];
    }
    if (lower.contains('clean')) {
      return [
        'Full Home Deep Clean',
        'Kitchen Cleaning',
        'Bathroom Scrub',
        'Sofa Shampoo',
      ];
    }
    if (lower.contains('carpent')) {
      return [
        'Furniture Repair',
        'Door & Window',
        'Lock Installation',
        'Custom Woodwork',
      ];
    }
    if (lower.contains('paint')) {
      return [
        'Interior Painting',
        'Exterior Painting',
        'Wall Putty & Primer',
        'Waterproofing',
      ];
    }
    if (lower.contains('ac')) {
      return [
        'Filter Cleaning',
        'Gas Refill',
        'Cooling Issue Repair',
        'Installation/Uninstallation',
      ];
    }
    if (lower.contains('appliance')) {
      return [
        'Washing Machine',
        'Refrigerator',
        'Microwave',
        'TV Mounting/Repair',
      ];
    }
    return [
      'General Inspection',
      'Repair & Fix',
      'New Installation',
      'Maintenance',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serviceAsync = ref.watch(serviceDetailProvider(widget.serviceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: serviceAsync.when(
        data: (ServiceItem? service) {
          final item = service ?? widget.initialService;
          if (item == null) {
            return SafeArea(
              child: EmptyState(
                title: l10n.noResultsFound,
                description: l10n.tryDifferentSearch,
              ),
            );
          }

          final subServices = _getSubServicesFor(item.name);

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Hero Header
                  SliverAppBar(
                    expandedHeight: 240,
                    pinned: true,
                    backgroundColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black54
                              : Colors.white.withValues(alpha: 0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 18,
                        ),
                      ),
                      onPressed: () {
                        KayloFeedback.tap();
                        context.pop();
                      },
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.brandPrimary.withValues(alpha: 0.25),
                              isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surface,
                            ],
                          ),
                        ),
                        child: Center(
                          child:
                              item.iconPath.isNotEmpty &&
                                  item.iconPath.startsWith('assets')
                              ? Image.asset(
                                  item.iconPath,
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.handyman_rounded,
                                    size: 80,
                                    color: AppColors.brandPrimary,
                                  ),
                                )
                              : const Icon(
                                  Icons.handyman_rounded,
                                  size: 80,
                                  color: AppColors.brandPrimary,
                                ),
                        ),
                      ),
                    ),
                  ),

                  // Service Content
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.l,
                      AppSpacing.m,
                      AppSpacing.l,
                      120, // clearance for bottom booking bar
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Title & Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                    ),
                              ),
                            ),
                            const RatingStars(rating: 4.8, reviewCount: 150),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.s),

                        // Subtitle
                        Text(
                          l10n.professionalAtDoorstep,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.l),

                        // Description Card
                        if (item.description.isNotEmpty) ...[
                          KayloCard(
                            padding: const EdgeInsets.all(AppSpacing.m),
                            child: Text(
                              item.description,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(height: 1.4),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                        ],

                        // Popular Sub-services Section
                        Text(
                          l10n.popularSubServices,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        Text(
                          l10n.selectSubServices,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.m),

                        Wrap(
                          spacing: AppSpacing.s,
                          runSpacing: AppSpacing.s,
                          children: subServices.map((subService) {
                            final isSelected = _selectedSubServices.contains(
                              subService,
                            );
                            return FilterChip(
                              label: Text(subService),
                              selected: isSelected,
                              onSelected: (selected) {
                                KayloFeedback.tap();
                                setState(() {
                                  if (selected) {
                                    _selectedSubServices.add(subService);
                                  } else {
                                    _selectedSubServices.remove(subService);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Price & Estimated Time Card
                        KayloCard(
                          padding: const EdgeInsets.all(AppSpacing.l),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.startingFrom,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '₹${item.basePrice.toInt()}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.brandPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    color: AppColors.brandPrimary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${item.estimatedDurationMinutes ?? 60} mins',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),

              // Bottom Sticky "Book Now" Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.m,
                    AppSpacing.l,
                    AppSpacing.l,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.startingFrom,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${item.basePrice.toInt()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        flex: 2,
                        child: KayloButton(
                          text: l10n.bookNow,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () {
                            KayloFeedback.press();
                            // Navigates to Worker List passing serviceId
                            context.push(
                              '${Routes.workerList}?serviceId=${item.id}&serviceName=${Uri.encodeComponent(item.name)}',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const SafeArea(
          child: Center(
            child: ShimmerBox(width: double.infinity, height: double.infinity),
          ),
        ),
        error: (err, stack) => SafeArea(
          child: ErrorState(
            message: err.toString(),
            onRetry: () =>
                ref.invalidate(serviceDetailProvider(widget.serviceId)),
          ),
        ),
      ),
    );
  }
}
