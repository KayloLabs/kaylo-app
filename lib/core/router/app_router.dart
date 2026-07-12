import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import '../widgets/kaylo_bottom_nav.dart';
import '../widgets/widgetbook_screen.dart';
import '../services/storage_service.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';

class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;
}

final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(
  AuthStateNotifier.new,
);

final goRouterProvider = Provider<GoRouter>((ref) {
  // final isAuth = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: Routes.splash,
    redirect: (context, state) {
      // final loggedIn = isAuth;
      // final isGoingToLogin = state.matchedLocation == Routes.login ||
      //                        state.matchedLocation == Routes.signup ||
      //                        state.matchedLocation == Routes.otp;

      // Basic Auth guard
      // for now, if going to a protected route and not logged in, we let it slide for UI testing,
      //but in real app we redirect to login.
      // Uncomment to enforce:
      //if (!loggedIn && !isGoingToLogin && state.matchedLocation != Routes.splash) {
      //   return Routes.login;
      // }

      return null; // No redirect
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
        builder: (context, state) =>
            const Placeholder(child: Text('Login Screen')),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) =>
            const Placeholder(child: Text('Signup Screen')),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (context, state) =>
            const Placeholder(child: Text('OTP Screen')),
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
                    const Placeholder(child: Text('Profile Tab')),
                routes: [
                  GoRoute(
                    path: Routes.settings,
                    builder: (context, state) =>
                        const Placeholder(child: Text('Settings')),
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
