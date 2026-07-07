import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

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
        builder: (context, state) =>
            const Placeholder(child: Text('Splash Screen')),
      ),
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) =>
            const Placeholder(child: Text('Onboarding Screen')),
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
      // ShellRoute for Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          // This would be replaced by the actual KayloBottomNav scaffold
          return Scaffold(
            body: child,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _calculateSelectedIndex(state.matchedLocation),
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go(Routes.dashboard);
                    break;
                  case 1:
                    context.go(Routes.bookings);
                    break;
                  case 2:
                    context.go(Routes.careHome);
                    break;
                  case 3:
                    context.go(Routes.messages);
                    break;
                  case 4:
                    context.go(Routes.profile);
                    break;
                }
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.list),
                  label: 'Bookings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: 'Care',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  label: 'Messages',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (context, state) =>
                const Placeholder(child: Text('Home Dashboard')),
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
          GoRoute(
            path: Routes.bookings,
            builder: (context, state) =>
                const Placeholder(child: Text('Bookings Tab')),
          ),
          GoRoute(
            path: Routes.careHome,
            builder: (context, state) =>
                const Placeholder(child: Text('Care Mode')),
          ),
          GoRoute(
            path: Routes.messages,
            builder: (context, state) =>
                const Placeholder(child: Text('Messages')),
          ),
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
  );
});

int _calculateSelectedIndex(String location) {
  if (location.startsWith(Routes.dashboard)) return 0;
  if (location.startsWith(Routes.bookings)) return 1;
  if (location.startsWith(Routes.careHome)) return 2;
  if (location.startsWith(Routes.messages)) return 3;
  if (location.startsWith(Routes.profile)) return 4;
  return 0;
}
