import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/worker.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/services/feedback_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/avatar_circle.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/kaylo_button.dart';
import '../../../../core/widgets/kaylo_card.dart';
import '../../../../core/widgets/rating_stars.dart';
import '../../../../core/widgets/shimmer_box.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../application/workers_providers.dart';

class WorkerProfileScreen extends ConsumerWidget {
  final String workerId;
  final String? serviceId;
  final Worker? initialWorker;

  const WorkerProfileScreen({
    super.key,
    required this.workerId,
    this.serviceId,
    this.initialWorker,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workerAsync = ref.watch(workerDetailProvider(workerId));
    final reviewsAsync = ref.watch(workerReviewsProvider(workerId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          l10n.workerProfile,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
      body: workerAsync.when(
        data: (worker) {
          final w = worker;
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.l,
                  AppSpacing.m,
                  AppSpacing.l,
                  120, // clearance for bottom booking button
                ),
                children: [
                  // Profile Header Card
                  KayloCard(
                    padding: const EdgeInsets.all(AppSpacing.l),
                    child: Column(
                      children: [
                        AvatarCircle(
                          imageUrl: w.profileImageUrl,
                          fallbackText: w.name,
                          radius: 42,
                        ),
                        const SizedBox(height: AppSpacing.m),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              w.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (w.isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.brandPrimary,
                                size: 22,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          w.location,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.s),
                        RatingStars(
                          rating: w.rating,
                          reviewCount: w.reviewsCount,
                        ),
                        const SizedBox(height: AppSpacing.m),

                        // Trust Score Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.m,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                color: AppColors.brandPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${w.trustScore.toInt()}% ${l10n.trustScore}',
                                style: const TextStyle(
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Quick Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: '${w.totalJobs}',
                          subtitle: l10n.completedJobs,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: _StatCard(
                          title: '${(w.trustScore / 15).clamp(3, 15).toInt()}+ yrs',
                          subtitle: l10n.yearsExperience,
                          icon: Icons.work_outline_rounded,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.m),
                      Expanded(
                        child: _StatCard(
                          title: '< 30m',
                          subtitle: l10n.responseTime,
                          icon: Icons.timer_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // About / Bio Section
                  Text(
                    l10n.about,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  KayloCard(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Text(
                      'Dedicated and experienced service professional with a track record of delivering clean, punctual, and high-quality work. Fluent in Malayalam and English with full verification and safety clearance.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Certifications Section
                  Text(
                    l10n.certifications,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  KayloCard(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    child: Column(
                      children: [
                        _buildCertRow(
                          icon: Icons.badge_outlined,
                          title: 'Government Identity Verified',
                          subtitle: 'Aadhaar / Voter ID check passed',
                        ),
                        const Divider(height: AppSpacing.l),
                        _buildCertRow(
                          icon: Icons.verified_user_outlined,
                          title: 'Police Clearance Verified',
                          subtitle: 'Criminal background check clear',
                        ),
                        const Divider(height: AppSpacing.l),
                        _buildCertRow(
                          icon: Icons.star_outline_rounded,
                          title: 'Kaylo Skill Certified',
                          subtitle: 'Practical skills tested and certified',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),

                  // Customer Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.customerReviews,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '(${w.reviewsCount})',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s),

                  reviewsAsync.when(
                    data: (reviews) {
                      if (reviews.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(AppSpacing.m),
                          child: Text(
                            'No reviews yet for this professional.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: reviews.map((r) => _buildReviewCard(r, context)).toList(),
                      );
                    },
                    loading: () => const ShimmerBox(
                      width: double.infinity,
                      height: 100,
                    ),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),

              // Bottom Sticky "Book Worker" Bar
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
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surface,
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
                            const Text(
                              'Hourly Rate',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${(w.hourlyRate ?? 300).toInt()}/hr',
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
                          text: l10n.bookService,
                          icon: Icons.calendar_today_rounded,
                          onPressed: () {
                            KayloFeedback.press();
                            // Handoff to M4's booking flow: {serviceId, workerId}
                            context.push(
                              '${Routes.bookService}?serviceId=${serviceId ?? ''}&workerId=${w.id}',
                              extra: {
                                'serviceId': serviceId,
                                'workerId': w.id,
                                'worker': w,
                              },
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
        loading: () => const Center(
          child: ShimmerBox(
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        error: (err, stack) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(workerDetailProvider(workerId)),
        ),
      ),
    );
  }

  Widget _buildCertRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.brandPrimary, size: 20),
        ),
        const SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 18,
        ),
      ],
    );
  }

  Widget _buildReviewCard(WorkerReview review, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.m),
      child: KayloCard(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AvatarCircle(
                  imageUrl: review.avatarUrl,
                  fallbackText: review.customerName,
                  radius: 18,
                ),
                const SizedBox(width: AppSpacing.s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      RatingStars(rating: review.rating),
                    ],
                  ),
                ),
                Text(
                  '${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              review.comment,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return KayloCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.m,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.brandPrimary, size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
