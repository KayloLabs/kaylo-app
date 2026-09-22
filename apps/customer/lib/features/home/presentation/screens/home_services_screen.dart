import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kaylo_core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/home_providers.dart';

class HomeServicesScreen extends ConsumerWidget {
  const HomeServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final homeServicesAsync = ref.watch(serviceListProvider('home'));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.homeServices,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            KayloFeedback.tap();
            context.pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: l10n.searchServices,
            onPressed: () {
              KayloFeedback.tap();
              context.push(Routes.search);
            },
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: homeServicesAsync.when(
          data: (services) {
            if (services.isEmpty) {
              return EmptyState(
                title: l10n.noResultsFound,
                description: l10n.tryDifferentSearch,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.l),
              itemCount: services.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.m),
              itemBuilder: (context, index) {
                final service = services[index];
                return _HomeServiceRow(service: service);
              },
            );
          },
          loading: () => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.l),
            itemCount: 6,
            separatorBuilder: (context, index) =>
                const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) =>
                const ShimmerBox(width: double.infinity, height: 84),
          ),
          error: (err, stack) => ErrorState(
            message: err.toString(),
            onRetry: () => ref.invalidate(serviceListProvider('home')),
          ),
        ),
      ),
    );
  }
}

class _HomeServiceRow extends StatelessWidget {
  final ServiceItem service;

  const _HomeServiceRow({required this.service});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KayloCard(
      onTap: () {
        KayloFeedback.tap();
        context.push(
          '${Routes.serviceDetails}?id=${service.id}',
          extra: service,
        );
      },
      padding: const EdgeInsets.all(AppSpacing.m),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceTintDark : AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Center(
              child:
                  service.iconPath.isNotEmpty &&
                      service.iconPath.startsWith('assets')
                  ? Image.asset(
                      service.iconPath,
                      width: 36,
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        _getIconForService(service.name),
                        color: AppColors.brandPrimary,
                        size: 28,
                      ),
                    )
                  : Icon(
                      _getIconForService(service.name),
                      color: AppColors.brandPrimary,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.description.isNotEmpty
                      ? service.description
                      : l10n.professionalAtDoorstep,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.startingFrom} ₹${service.basePrice.toInt()}',
                  style: const TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            size: 24,
          ),
        ],
      ),
    );
  }

  IconData _getIconForService(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('plumb')) return Icons.plumbing_rounded;
    if (lower.contains('electric')) return Icons.electrical_services_rounded;
    if (lower.contains('carpent')) return Icons.carpenter_rounded;
    if (lower.contains('paint')) return Icons.format_paint_rounded;
    if (lower.contains('clean')) return Icons.cleaning_services_rounded;
    if (lower.contains('ac')) return Icons.ac_unit_rounded;
    if (lower.contains('appliance')) return Icons.home_repair_service_rounded;
    if (lower.contains('garden')) return Icons.yard_rounded;
    return Icons.handyman_rounded;
  }
}
