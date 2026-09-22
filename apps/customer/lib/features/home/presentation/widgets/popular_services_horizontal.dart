import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/models/service_item.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/router/service_routes.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/widgets/section_header.dart';
import 'package:kaylo_ui/widgets/kaylo_liquid_glass.dart';
import '../../../../l10n/generated/app_localizations.dart';

class PopularServicesHorizontal extends StatelessWidget {
  final List<ServiceItem> services;

  /// Section heading override; defaults to "Popular Services". The
  /// dashboard passes "Recommended for you" when the list is personalized.
  final String? title;

  const PopularServicesHorizontal({
    super.key,
    required this.services,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: title ?? AppLocalizations.of(context)!.popularServices,
          actionText: '${AppLocalizations.of(context)!.seeAll} >',
          onActionPressed: () {
            KayloFeedback.tap();
            context.push(Routes.homeServices);
          },
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height:
              140, // Increased height to prevent vertical overflow for 2 lines
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            clipBehavior: Clip.none,
            itemCount: services.length,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.m),
            itemBuilder: (context, index) {
              final service = services[index];
              return SizedBox(
                width: 120, // Increased width
                child: KayloLiquidGlass(
                  borderRadius: AppRadius.card,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      onTap: () {
                        KayloFeedback.tap();
                        openService(GoRouter.of(context), service);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.s),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(
                                service.iconPath,
                                width: 80, // Increased size
                                height: 80, // Increased size
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: AppSpacing.s),
                              Text(
                                service.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color:
                                          Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                      height: 1.1,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
