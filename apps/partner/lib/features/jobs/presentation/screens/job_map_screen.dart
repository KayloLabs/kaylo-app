import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/services/feedback_service.dart';
import 'package:kaylo_ui/theme/app_colors.dart';
import 'package:kaylo_ui/theme/app_radius.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';
import 'package:kaylo_ui/widgets/empty_state.dart';
import 'package:kaylo_ui/widgets/kaylo_button.dart';
import 'package:kaylo_ui/widgets/kaylo_loader.dart';
import 'package:kaylo_ui/widgets/kaylo_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../application/jobs_providers.dart';
import '../../domain/geo.dart';
import '../widgets/job_map.dart';

class JobMapScreen extends ConsumerWidget {
  final String jobId;
  final bool showTiles;

  const JobMapScreen({
    super.key,
    required this.jobId,
    this.showTiles = true,
  });

  Future<void> _openGoogleMaps(BuildContext context, String address) async {
    final uri = Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': address,
    });
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      KayloSnackbar.showInfo(
        context,
        'Navigation is unavailable on this device',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final jobAsync = ref.watch(jobDetailProvider(jobId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.jobLocationMap),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: jobAsync.when(
        data: (job) {
          if (job == null) {
            return const Center(
              child: EmptyState(
                title: 'Job not found',
                description: 'This job could not be located.',
                icon: Icons.map_outlined,
              ),
            );
          }

          final eta = etaMinutes(job.distanceKm);

          return Stack(
            children: [
              // Full-screen interactive map
              Positioned.fill(
                child: JobMap(
                  job: job,
                  interactive: true,
                  showTiles: showTiles,
                  showExpandButton: false,
                  padding: 80.0,
                ),
              ),

              // Bottom information floating sheet
              Positioned(
                left: AppSpacing.l,
                right: AppSpacing.l,
                bottom: AppSpacing.xl,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 18,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.s),
                          Expanded(
                            child: Text(
                              job.customerName,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Text(
                            '${job.distanceKm} km · ${l10n.aboutMinutes(eta)}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.farmAccent,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s),
                      Text(
                        job.addressLine,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      KayloButton(
                        text: l10n.openInGoogleMaps,
                        icon: Icons.navigation_rounded,
                        onPressed: () {
                          KayloFeedback.tap();
                          _openGoogleMaps(context, job.addressLine);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: KayloLoader()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
