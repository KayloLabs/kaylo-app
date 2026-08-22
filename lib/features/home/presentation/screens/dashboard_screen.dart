import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/dashboard_controller.dart';
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: dashboardState.when(
          data: (state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.l,
                vertical: AppSpacing.m,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GreetingHeader(
                    location: state.location,
                    notificationCount: 3, // Mocked from reference image
                    userName: state.userName,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  const DashboardSearchBar(),
                  const SizedBox(height: AppSpacing.xl),
                  const HeroBanner(),
                  const SizedBox(height: AppSpacing.xl),
                  const ModeSwitcherSection(),
                  const SizedBox(height: AppSpacing.xl),
                  PopularServicesHorizontal(services: state.popularServices),
                  const SizedBox(height: AppSpacing.xl),
                  const BottomPromoBanner(),
                  const SizedBox(height: 120), // Padding for bottom nav
                ],
              ),
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
