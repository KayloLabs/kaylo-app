import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/error_state.dart';
import 'package:kaylo_ui/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/farm_providers.dart';
import '../widgets/farm_service_card.dart';

class FarmServicesScreen extends ConsumerWidget {
  const FarmServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final services = ref.watch(farmServicesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.farmServices)),
      body: services.when(
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
              title: l10n.noServicesTitle,
              description: l10n.noServicesDescription,
              icon: Icons.agriculture_rounded,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.l,
              AppSpacing.m,
              AppSpacing.l,
              AppSpacing.xxxl,
            ),
            itemCount: list.length + 1,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.m),
            itemBuilder: (context, index) {
              if (index == 0) return const _FarmIntro();
              final service = list[index - 1];
              return FarmServiceCard(
                service: service,
                onTap: () {
                  KayloFeedback.tap();
                  context.push(Routes.farmService(service.id));
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
          onRetry: () => ref.invalidate(farmServicesProvider),
        ),
      ),
    );
  }
}

class _FarmIntro extends StatelessWidget {
  const _FarmIntro();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.l),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.farmAccent.withValues(alpha: isDark ? 0.28 : 0.22),
            AppColors.farmAccent.withValues(alpha: isDark ? 0.10 : 0.06),
          ],
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets_kaylo/3d_transparent/mode_farm.png',
            width: 72,
            height: 72,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: AppSpacing.l),
          Expanded(
            child: Text(
              l10n.farmServicesTagline,
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
