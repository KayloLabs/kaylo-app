import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/farm_providers.dart';
import '../../domain/farm_service_info.dart';
import 'farm_labels.dart';

class FarmServiceCard extends ConsumerWidget {
  final ServiceItem service;
  final VoidCallback onTap;

  const FarmServiceCard({super.key, required this.service, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = farmInfoFor(service);
    final summary = ref
        .watch(farmWorkersProvider(service.id))
        .whenOrNull(data: ratingSummary);

    return KayloCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(AppSpacing.s),
            decoration: BoxDecoration(
              color: AppColors.farmAccent.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Image.asset(service.iconPath, fit: BoxFit.contain),
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  service.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.s),
                // Stacked, not side by side: on narrow phones the stars
                // and a "per tree" price tag cannot share one line.
                if (summary != null) ...[
                  RatingStars(
                    rating: summary.rating,
                    reviewCount: summary.reviews,
                    size: 14,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                PriceTag(
                  amount: service.basePrice,
                  suffix: l10n.perUnit(farmUnitLabel(l10n, info.unit)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
