import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

import '../../../features/auth/application/partner_session.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/splash/presentation/screens/partner_splash_screen.dart';
import '../../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../../features/jobs/presentation/screens/jobs_home_screen.dart';
import '../../../features/jobs/presentation/screens/job_history_screen.dart';
import '../../../features/profile/presentation/screens/partner_profile_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'routes.dart';

final partnerRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool>(false);
  ref.onDispose(listenable.dispose);

  ref.listen(partnerAuthStateProvider, (_, _) {
    listenable.value = !listenable.value;
  });

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: listenable,
    redirect: (context, state) async {
      // The splash decides where to go once it has checked the session.
      if (state.matchedLocation == Routes.splash) return null;
      final isLoggedIn = await ref
          .read(partnerAuthRepositoryProvider)
          .isAuthenticated();
      final isGoingToLogin = state.matchedLocation.startsWith(Routes.login);

      if (!isLoggedIn && !isGoingToLogin) return Routes.login;
      if (isLoggedIn && isGoingToLogin) return Routes.jobs;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) => const PartnerSplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const PartnerLoginScreen(),
      ),
      // Job detail – full-screen over the shell
      GoRoute(
        path: '/jobs/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobDetailScreen(jobId: id);
        },
      ),
      GoRoute(
        path: Routes.history,
        builder: (_, _) => const JobHistoryScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _PartnerShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.jobs,
                builder: (_, _) => const JobsHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.earnings,
                builder: (_, _) => const EarningsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => const PartnerProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Shell scaffold – bottom navigation bar for the partner app
// ---------------------------------------------------------------------------

class _PartnerShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const _PartnerShell({required this.shell});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.work_outline_rounded),
            selectedIcon: const Icon(
              Icons.work_rounded,
              color: AppColors.brandPrimary,
            ),
            label: l10n.tabJobs,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bar_chart_outlined),
            selectedIcon: const Icon(
              Icons.bar_chart_rounded,
              color: AppColors.brandPrimary,
            ),
            label: l10n.tabEarnings,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(
              Icons.person_rounded,
              color: AppColors.brandPrimary,
            ),
            label: l10n.tabProfile,
          ),
        ],
      ),
    );
  }
}
