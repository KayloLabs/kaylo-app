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
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/service_providers.dart';
import '../widgets/service_card.dart';
import '../widgets/service_labels.dart';

const _knownCategories = {'home', 'farm', 'care'};

/// Every service in one category, or the whole catalog for 'all'.
class ServicesListScreen extends ConsumerWidget {
  final String category;

  const ServicesListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final key = _knownCategories.contains(category) ? category : 'all';
    final services = ref.watch(servicesByCategoryProvider(key));

    return Scaffold(
      appBar: AppBar(title: Text(categoryTitle(l10n, key))),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(servicesByCategoryProvider(key).future),
        child: services.when(
          data: (list) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              AppSpacing.xxxl,
            ),
            itemCount: list.isEmpty ? 2 : list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              if (index == 0) return _CategoryIntro(category: key);
              if (list.isEmpty) {
                return EmptyState(
                  title: l10n.noServicesTitle,
                  description: l10n.noServicesDescription,
                  icon: Icons.handyman_rounded,
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
          ),
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
            onRetry: () => ref.invalidate(servicesByCategoryProvider(key)),
          ),
        ),
      ),
    );
  }
}

class _CategoryIntro extends StatelessWidget {
  final String category;

  const _CategoryIntro({required this.category});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = categoryAccent(category);
    final (image, tagline) = switch (category) {
      'farm' => ('mode_farm.png', l10n.farmServicesTagline),
      'care' => ('mode_care.png', l10n.careServicesTagline),
      'home' => ('mode_home.png', l10n.homeServicesTagline),
      _ => ('mode_home.png', l10n.allServicesTagline),
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: isDark ? 0.28 : 0.22),
            accent.withValues(alpha: isDark ? 0.10 : 0.06),
          ],
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets_kaylo/3d_transparent/$image',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Text(
              tagline,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
