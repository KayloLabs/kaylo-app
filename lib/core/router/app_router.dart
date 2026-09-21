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
import '../../features/booking/domain/booking_receipt.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/bookings_screen.dart';
import '../../features/care/presentation/screens/emergency_sos_screen.dart';
import '../../features/care/presentation/screens/medicine_reminders_screen.dart';
import '../../features/care/presentation/screens/sos_history_screen.dart';
import '../../features/farm/domain/farm_booking_draft.dart';
import '../../features/farm/presentation/screens/farm_payment_screen.dart';
import '../../features/farm/presentation/screens/farm_schedule_screen.dart';
import '../../features/farm/presentation/screens/farm_service_details_screen.dart';
import '../../features/farm/presentation/screens/farm_services_screen.dart';
import '../../features/messages/presentation/screens/conversation_screen.dart';
import '../../features/messages/presentation/screens/messages_screen.dart';

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

      // Farm booking flow: catalog -> details -> schedule -> payment.
      // Full-screen (outside the shell) so checkout owns the bottom edge.
      GoRoute(
        path: Routes.farm,
        builder: (context, state) => const FarmServicesScreen(),
        routes: [
          GoRoute(
            path: ':serviceId',
            builder: (context, state) => FarmServiceDetailsScreen(
              serviceId: state.pathParameters['serviceId']!,
            ),
            routes: [
              GoRoute(
                path: 'schedule',
                builder: (context, state) => FarmScheduleScreen(
                  serviceId: state.pathParameters['serviceId']!,
                ),
              ),
              GoRoute(
                path: 'payment',
                builder: (context, state) => FarmPaymentScreen(
                  draft: state.extra as FarmBookingDraft?,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.bookingConfirmation,
        builder: (context, state) => BookingConfirmationScreen(
          receipt: state.extra as BookingReceipt?,
        ),
      ),
      GoRoute(
        path: '/chat/:threadId', // Routes.chat(id)
        builder: (context, state) => ConversationScreen(
          threadId: state.pathParameters['threadId']!,
        ),
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
                builder: (context, state) => const BookingsScreen(),
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
                    path: 'medicines', // Routes.careMedicines
                    builder: (context, state) =>
                        const MedicineRemindersScreen(),
                  ),
                  GoRoute(
                    path: 'sos', // Routes.careSos
                    builder: (context, state) => const EmergencySosScreen(),
                    routes: [
                      GoRoute(
                        path: 'history', // Routes.careSosHistory
                        builder: (context, state) => const SosHistoryScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.messages,
                builder: (context, state) => const MessagesScreen(),
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
