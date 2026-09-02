import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import '../widgets/kaylo_bottom_nav.dart';
import '../widgets/widgetbook_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/care/presentation/screens/care_home_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/auth/presentation/screens/location_setup_screen.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/care/presentation/screens/family_dashboard_screen.dart';

// AuthStateNotifier replaced by SessionController

final goRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool>(false);
  
  ref.listen(sessionControllerProvider, (previous, next) {
    listenable.value = !listenable.value;
  });

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final sessionState = ref.read(sessionControllerProvider);
      final isLoggedIn = sessionState.valueOrNull != null;
      final isGoingToLogin = state.matchedLocation.startsWith(Routes.login);

      // Allow splash, onboarding, and widgetbook to be accessed without auth
      if (state.matchedLocation == Routes.splash ||
          state.matchedLocation == Routes.onboarding ||
          state.matchedLocation == Routes.widgetbook) {
        return null;
      }

      // Basic Auth guard
      if (!isLoggedIn && !isGoingToLogin) {
         return Routes.login;
      }

      // If logged in and trying to access login, redirect to dashboard
      if (isLoggedIn && isGoingToLogin) {
         return Routes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: Routes.otp.replaceAll('/', ''), // e.g. otp relative
            builder: (context, state) {
              final phone = state.extra as String? ?? '';
              return OtpVerifyScreen(phone: phone);
            },
          ),
        ],
      ),
      GoRoute(
        path: Routes.location,
        builder: (context, state) => const LocationSetupScreen(),
      ),
      GoRoute(
        path: Routes.widgetbook,
        builder: (context, state) => const WidgetbookScreen(),
      ),
      // ShellRoute for Bottom Navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return KayloBottomNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.dashboard,
                builder: (context, state) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: Routes.serviceDetails,
                    builder: (context, state) =>
                        const Placeholder(child: Text('Service Details')),
                  ),
                  GoRoute(
                    path: Routes.workerList,
                    builder: (context, state) =>
                        const Placeholder(child: Text('Worker List')),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.bookings,
                builder: (context, state) =>
                    const Placeholder(child: Text('Bookings Tab')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.careHome,
                builder: (context, state) => const CareHomeScreen(),
                routes: [
                  GoRoute(
                    path: Routes.familyDashboard,
                    builder: (context, state) => const FamilyDashboardScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.messages,
                builder: (context, state) =>
                    const Placeholder(child: Text('Messages')),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (context, state) =>
                    const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: Routes.settings,
                    builder: (context, state) => const SettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
