import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';
import '../widgets/kaylo_bottom_nav.dart';
import '../widgets/widgetbook_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_services_screen.dart';
import '../../features/home/presentation/screens/service_details_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/workers/presentation/screens/worker_list_screen.dart';
import '../../features/workers/presentation/screens/worker_profile_screen.dart';
import '../../features/care/presentation/screens/care_home_screen.dart';
import '../../features/care/presentation/screens/doctor_appointment_screen.dart';
import '../../features/care/presentation/screens/caregiver_booking_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/auth/presentation/screens/location_setup_screen.dart';
import '../../features/auth/application/session_controller.dart';
import '../models/service_item.dart';
import '../models/worker.dart';

// AuthStateNotifier replaced by SessionController

final goRouterProvider = Provider<GoRouter>((ref) {
  final listenable = ValueNotifier<bool>(false);
  ref.onDispose(listenable.dispose);

  ref.listen(sessionControllerProvider, (previous, next) {
    listenable.value = !listenable.value;
  });

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: listenable,
    redirect: (context, state) {
      final sessionState = ref.read(sessionControllerProvider);
      final isLoggedIn = sessionState.whenOrNull(data: (user) => user) != null;
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
            path: 'otp', // absolute form is Routes.loginOtp
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
                    path: 'home-services',
                    builder: (context, state) => const HomeServicesScreen(),
                  ),
                  GoRoute(
                    path: 'service-details',
                    builder: (context, state) {
                      final id = state.uri.queryParameters['id'] ?? '';
                      final service = state.extra as ServiceItem?;
                      return ServiceDetailsScreen(
                        serviceId: id,
                        initialService: service,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'workers',
                    builder: (context, state) {
                      final serviceId =
                          state.uri.queryParameters['serviceId'] ?? '';
                      final serviceName =
                          state.uri.queryParameters['serviceName'];
                      return WorkerListScreen(
                        serviceId: serviceId,
                        serviceName: serviceName,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'worker-profile',
                    builder: (context, state) {
                      final workerId =
                          state.uri.queryParameters['workerId'] ?? '';
                      final serviceId =
                          state.uri.queryParameters['serviceId'];
                      final worker = state.extra as Worker?;
                      return WorkerProfileScreen(
                        workerId: workerId,
                        serviceId: serviceId,
                        initialWorker: worker,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const SearchScreen(),
                  ),
                  GoRoute(
                    path: 'book-service',
                    builder: (context, state) {
                      final serviceId =
                          state.uri.queryParameters['serviceId'] ?? '';
                      final workerId =
                          state.uri.queryParameters['workerId'] ?? '';
                      return Scaffold(
                        appBar: AppBar(title: const Text('Book Service')),
                        body: Center(
                          child: Text(
                            'Booking Service: $serviceId\nWorker: $workerId\n(Handoff to M4)',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
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
                    path: 'doctor-appointment',
                    builder: (context, state) =>
                        const DoctorAppointmentScreen(),
                  ),
                  GoRoute(
                    path: 'caregiver-booking',
                    builder: (context, state) =>
                        const CaregiverBookingScreen(),
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
