import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/kaylo_loader.dart';
import '../../../../core/widgets/price_tag.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/farm_providers.dart';
import '../../domain/farm_service_info.dart';
import '../widgets/farm_labels.dart';

class FarmServiceDetailsScreen extends ConsumerWidget {
  final String serviceId;

  const FarmServiceDetailsScreen({super.key, required this.serviceId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final service = ref.watch(farmServiceProvider(serviceId));

    return service.when(
      data: (service) => _Details(service: service),
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: KayloLoader()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorState(
          title: l10n.somethingWentWrong,
          message: error.toString(),
          onRetry: () => ref.invalidate(farmServiceProvider(serviceId)),
        ),
      ),
    );
  }
}

class _Details extends ConsumerWidget {
  final ServiceItem service;

  const _Details({required this.service});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = farmInfoFor(service);
    final workers = ref.watch(farmWorkersProvider(service.id));
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(title: Text(service.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.xxl,
        ),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.farmAccent.withValues(alpha: isDark ? 0.30 : 0.26),
                  AppColors.farmAccent.withValues(alpha: isDark ? 0.08 : 0.05),
                ],
              ),
            ),
            child: Center(
              child: Image.asset(
                service.iconPath,
                width: 140,
                height: 140,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  service.name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: AppSpacing.m),
              PriceTag(
                amount: service.basePrice,
                isLarge: true,
                suffix: l10n.perUnit(farmUnitLabel(l10n, info.unit)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),
          Text(
            service.description,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: secondary, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.l),

          // Availability: real worker data, never an invented number.
          workers.when(
            data: (list) {
              final summary = ratingSummary(list);
              return Row(
                children: [
                  Icon(
                    list.isEmpty
                        ? Icons.hourglass_top_rounded
                        : Icons.verified_user_rounded,
                    size: 20,
                    color: list.isEmpty ? secondary : AppColors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: Text(
                      list.isEmpty
                          ? l10n.noWorkersYet
                          : l10n.workersNearYou(list.length),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (summary != null)
                    RatingStars(
                      rating: summary.rating,
                      reviewCount: summary.reviews,
                      size: 16,
                    ),
                ],
              );
            },
            loading: () => const SizedBox(height: 20),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xxl),

          SectionHeader(title: l10n.serviceStandards),
          const SizedBox(height: AppSpacing.m),
          KayloCard(
            child: Column(
              children: [
                for (final standard in info.standards)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.s),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.brandPrimaryBright,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Text(
                            farmStandardLabel(l10n, standard),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          Container(
            padding: const EdgeInsets.all(AppSpacing.l),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceTintDark : AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.homeAccent),
                const SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    l10n.liveTotalNote,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: secondary, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.l,
          AppSpacing.s,
          AppSpacing.l,
          AppSpacing.l,
        ),
        child: KayloButton(
          text: l10n.bookNow,
          icon: Icons.calendar_month_rounded,
          onPressed: () => context.push(Routes.farmSchedule(service.id)),
        ),
      ),
    );
  }
}
