import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/dashboard_controller.dart';
import '../../application/personalization_providers.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../widgets/greeting_header.dart';
import '../widgets/dashboard_search_bar.dart';
import '../widgets/hero_banner.dart';
import '../widgets/mode_switcher_section.dart';
import '../widgets/popular_services_horizontal.dart';
import '../widgets/bottom_promo_banner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);
    final recommended = ref.watch(recommendedServicesProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: dashboardState.when(
          data: (state) {
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.m,
                    AppSpacing.l,
                    AppSpacing.s,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: GreetingHeader(
                      location: state.location,
                      notificationCount:
                          unreadCount.whenOrNull(data: (c) => c) ?? 0,
                      userName: state.userName,
                    ),
                  ),
                ),
                // The search bar stays pinned while everything else
                // scrolls beneath it; its liquid glass frosts whatever
                // passes underneath.
                const SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedSearchBarDelegate(),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.l,
                    AppSpacing.m,
                    AppSpacing.l,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HeroBanner(),
                        const SizedBox(height: AppSpacing.xl),
                        const ModeSwitcherSection(),
                        const SizedBox(height: AppSpacing.xl),
                        // Personalized ranking when booking history
                        // exists; otherwise the plain popular list.
                        switch (recommended) {
                          AsyncData(:final value) =>
                            PopularServicesHorizontal(
                              services: value.services,
                              title: value.personalized
                                  ? AppLocalizations.of(context)!
                                      .recommendedForYou
                                  : null,
                            ),
                          _ => PopularServicesHorizontal(
                              services: state.popularServices),
                        },
                        const SizedBox(height: AppSpacing.xl),
                        const BottomPromoBanner(),
                        const SizedBox(height: 120), // bottom nav space
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.brandPrimary),
          ),
          error: (error, stack) => Center(
            child: Text('Error loading dashboard: $error'),
          ),
        ),
      ),
    );
  }
}

class _PinnedSearchBarDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedSearchBarDelegate();

  static const double _height = 72;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: DashboardSearchBar(),
      ),
    );
  }

  @override
  bool shouldRebuild(_PinnedSearchBarDelegate oldDelegate) => false;
}
