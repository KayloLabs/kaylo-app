import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_ui/theme/app_colors.dart';

import '../../features/auth/application/partner_session.dart';
import '../../features/auth/domain/partner_auth_repository.dart';
import '../../features/auth/presentation/screens/change_password_screen.dart';
import '../../features/auth/presentation/screens/account_status_screen.dart';
import '../../features/onboarding/presentation/screens/worker_application_screen.dart';
import '../../features/onboarding/presentation/screens/worker_application_status_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/availability/presentation/screens/availability_screen.dart';
import '../../features/splash/presentation/screens/partner_splash_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/jobs/presentation/screens/job_detail_screen.dart';
import '../../features/jobs/presentation/screens/jobs_home_screen.dart';
import '../../features/jobs/presentation/screens/job_history_screen.dart';
import '../../features/profile/presentation/screens/partner_profile_screen.dart';
import '../../l10n/generated/app_localizations.dart';
import 'routes.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';
import '../../features/messages/presentation/screens/conversation_screen.dart';
import '../../features/notifications/presentation/screens/alerts_screen.dart';
import '../../features/notifications/application/alerts_providers.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart';

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
      if (state.matchedLocation == Routes.splash) return null;
      final access = await ref
          .read(partnerAuthRepositoryProvider)
          .checkAccess();
      return partnerRedirect(access, state.matchedLocation);
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
      GoRoute(
        path: Routes.apply,
        builder: (_, _) => const WorkerApplicationScreen(),
      ),
      GoRoute(
        path: Routes.applicationStatus,
        builder: (_, state) => WorkerApplicationStatusScreen(
          initialReference: state.uri.queryParameters['reference'],
        ),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, _) => const PartnerChangePasswordScreen(),
      ),
      GoRoute(
        path: Routes.accountStatus,
        builder: (_, _) => const PartnerAccountStatusScreen(),
      ),
      GoRoute(
        path: Routes.messages,
        builder: (_, _) => const PartnerMessagesScreen(),
      ),
      GoRoute(
        path: '${Routes.messages}/:jobId',
        builder: (_, state) =>
            PartnerConversationScreen(jobId: state.pathParameters['jobId']!),
      ),
      GoRoute(
        path: Routes.reviews,
        builder: (_, _) => const PartnerReviewsScreen(),
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
      GoRoute(
        path: Routes.availability,
        builder: (_, _) => const AvailabilityScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.alerts,
                builder: (_, _) => const PartnerAlertsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Every deep link passes the same identity and verification checks.
String? partnerRedirect(PartnerAccess access, String location) {
  final public = [
    Routes.login,
    Routes.apply,
    Routes.applicationStatus,
  ].contains(location);
  String? target;
  switch (access.status) {
    case PartnerAccessStatus.signedOut:
      target = public ? null : Routes.login;
    case PartnerAccessStatus.passwordChange:
      target = Routes.changePassword;
    case PartnerAccessStatus.unavailable:
      target =
          [
            Routes.login,
            Routes.apply,
            Routes.applicationStatus,
            Routes.accountStatus,
          ].contains(location)
          ? null
          : Routes.accountStatus;
    case PartnerAccessStatus.registration:
      target =
          [
            Routes.apply,
            Routes.applicationStatus,
            Routes.accountStatus,
          ].contains(location)
          ? null
          : Routes.accountStatus;
    case PartnerAccessStatus.verification:
      target = [Routes.profile, Routes.accountStatus].contains(location)
          ? null
          : Routes.accountStatus;
    case PartnerAccessStatus.ready:
      target =
          public ||
              [Routes.changePassword, Routes.accountStatus].contains(location)
          ? Routes.jobs
          : null;
  }
  return target == location ? null : target;
}

// ---------------------------------------------------------------------------
// Shell scaffold – bottom navigation bar for the partner app
// ---------------------------------------------------------------------------

class _PartnerShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell shell;

  const _PartnerShell({required this.shell});

  @override
  ConsumerState<_PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends ConsumerState<_PartnerShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(
        ref.read(partnerAuthRepositoryProvider).checkAccess(forceRefresh: true),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.shell;
    final unread = ref.watch(partnerAlertUnreadProvider);
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
          NavigationDestination(
            icon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            selectedIcon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const Icon(
                Icons.notifications_rounded,
                color: AppColors.brandPrimary,
              ),
            ),
            label: l10n.alertsTitle,
          ),
        ],
      ),
    );
  }
}
