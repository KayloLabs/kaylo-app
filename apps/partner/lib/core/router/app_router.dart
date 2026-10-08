import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/theme/app_spacing.dart';

import '../../../features/auth/application/partner_session.dart';
import '../../../features/auth/presentation/screens/login_screen.dart';
import '../../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../../features/jobs/presentation/screens/job_map_screen.dart';
import '../../../features/jobs/presentation/screens/jobs_home_screen.dart';
import '../../../features/jobs/presentation/screens/job_history_screen.dart';
import '../../../features/profile/presentation/screens/partner_profile_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import '../widgets/partner_tab_bar.dart';
import 'routes.dart';

final partnerRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool>(false);
  ref.onDispose(listenable.dispose);

  ref.listen(partnerAuthStateProvider, (_, _) {
    listenable.value = !listenable.value;
  });

  return GoRouter(
    initialLocation: Routes.jobs,
    refreshListenable: listenable,
    redirect: (context, state) async {
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
      // Full-screen interactive job map
      GoRoute(
        path: Routes.jobMapRoute,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return JobMapScreen(jobId: id);
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
      extendBody: true,
      body: shell,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.m,
            0,
            AppSpacing.m,
            AppSpacing.s,
          ),
          child: PartnerTabBar(
            currentIndex: shell.currentIndex,
            onSelected: (index) => shell.goBranch(
              index,
              initialLocation: index == shell.currentIndex,
            ),
            items: [
              PartnerTabItem(
                icon: Icons.work_outline_rounded,
                selectedIcon: Icons.work_rounded,
                label: l10n.tabJobs,
              ),
              PartnerTabItem(
                icon: Icons.bar_chart_outlined,
                selectedIcon: Icons.bar_chart_rounded,
                label: l10n.tabEarnings,
              ),
              PartnerTabItem(
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: l10n.tabProfile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
