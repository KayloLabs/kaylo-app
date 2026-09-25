import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaylo_core/firebase/firebase_bootstrap.dart';

import 'kaylo_page.dart';
import 'routes.dart';
import '../widgets/kaylo_bottom_nav.dart';
import '../widgets/widgetbook_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/home/application/search_controller.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/screens/home_services_screen.dart';
import '../../features/home/presentation/screens/service_details_screen.dart';
import '../../features/home/presentation/screens/search_screen.dart';
import '../../features/workers/presentation/screens/worker_list_screen.dart';
import '../../features/workers/presentation/screens/worker_profile_screen.dart';
import '../../features/care/presentation/screens/care_home_screen.dart';
import '../../features/care/presentation/screens/doctor_appointment_screen.dart';
import '../../features/care/presentation/screens/caregiver_booking_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/saved_addresses_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_verify_screen.dart';
import '../../features/auth/presentation/screens/location_setup_screen.dart';
import '../../features/auth/application/session_controller.dart';
import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/models/worker.dart';
import '../../features/booking/domain/booking_receipt.dart';
import '../../features/booking/presentation/screens/booking_confirmation_screen.dart';
import '../../features/booking/presentation/screens/booking_details_screen.dart';
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
import '../../features/notifications/presentation/screens/notifications_screen.dart';

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
    // Screen views for Firebase Analytics on the root navigator (pushed
    // full-screen routes); tab switches inside the shell are not logged.
    observers: [
      if (FirebaseBootstrap.isReady)
        FirebaseAnalyticsObserver(analytics: FirebaseBootstrap.analytics),
    ],
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
        pageBuilder: (context, state) =>
            kayloPage(state: state, child: const FarmServicesScreen()),
        routes: [
          GoRoute(
            path: ':serviceId',
            pageBuilder: (context, state) => kayloPage(
              state: state,
              child: FarmServiceDetailsScreen(
                serviceId: state.pathParameters['serviceId']!,
              ),
            ),
            routes: [
              GoRoute(
                path: 'schedule',
                pageBuilder: (context, state) => kayloPage(
                  state: state,
                  child: FarmScheduleScreen(
                    serviceId: state.pathParameters['serviceId']!,
                  ),
                ),
              ),
              GoRoute(
                path: 'payment',
                pageBuilder: (context, state) => kayloPage(
                  state: state,
                  child: FarmPaymentScreen(
                    draft: state.extra as FarmBookingDraft?,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.bookingConfirmation,
        pageBuilder: (context, state) => kayloPage(
          state: state,
          child: BookingConfirmationScreen(
            receipt: state.extra as BookingReceipt?,
          ),
        ),
      ),

      // Home discovery: catalog -> details -> workers -> profile, and
      // search. Full-screen like the farm flow; the dashboard pushes in.
      GoRoute(
        path: Routes.homeServices,
        pageBuilder: (context, state) =>
            kayloPage(state: state, child: const HomeServicesScreen()),
      ),
      GoRoute(
        path: Routes.serviceDetails,
        pageBuilder: (context, state) => kayloPage(
          state: state,
          child: ServiceDetailsScreen(
            serviceId: state.uri.queryParameters['id'] ?? '',
            initialService: state.extra as ServiceItem?,
          ),
        ),
      ),
      GoRoute(
        path: Routes.workerList,
        pageBuilder: (context, state) => kayloPage(
          state: state,
          child: WorkerListScreen(
            serviceId: state.uri.queryParameters['serviceId'] ?? '',
            serviceName: state.uri.queryParameters['serviceName'],
          ),
        ),
      ),
      GoRoute(
        path: Routes.workerProfile,
        pageBuilder: (context, state) => kayloPage(
          state: state,
          child: WorkerProfileScreen(
            workerId: state.uri.queryParameters['workerId'] ?? '',
            serviceId: state.uri.queryParameters['serviceId'],
            initialWorker: state.extra as Worker?,
          ),
        ),
      ),
      // ?q= seeds the query (hero banner); `extra` carries filters picked
      // on the dashboard's tune button.
      GoRoute(
        path: Routes.search,
        pageBuilder: (context, state) => kayloPage(
          state: state,
          child: SearchScreen(
            initialQuery: state.uri.queryParameters['q'] ?? '',
            initialFilters: state.extra as SearchFilters?,
          ),
        ),
      ),
      // Booking handoff from a worker list or profile: the same schedule
      // and payment steps the farm flow uses, with the chosen worker
      // pinned on the draft.
      GoRoute(
        path: Routes.bookService,
        pageBuilder: (context, state) {
          final workerId = state.uri.queryParameters['workerId'];
          return kayloPage(
            state: state,
            child: FarmScheduleScreen(
              serviceId: state.uri.queryParameters['serviceId'] ?? '',
              workerId: workerId == null || workerId.isEmpty ? null : workerId,
            ),
          );
        },
      ),
      GoRoute(
        path: Routes.notifications,
        pageBuilder: (context, state) =>
            kayloPage(state: state, child: const NotificationsScreen()),
      ),
      GoRoute(
        path: '/chat/:threadId', // Routes.chat(id)
        pageBuilder: (context, state) => kayloPage(
          state: state,
          child: ConversationScreen(
            threadId: state.pathParameters['threadId']!,
          ),
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
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.bookings,
                builder: (context, state) => const BookingsScreen(),
                routes: [
                  GoRoute(
                    path: ':bookingId', // Routes.bookingDetails(id)
                    pageBuilder: (context, state) => kayloPage(
                      state: state,
                      child: BookingDetailsScreen(
                        bookingId: state.pathParameters['bookingId']!,
                      ),
                    ),
                  ),
                ],
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
                    pageBuilder: (context, state) => kayloPage(
                      state: state,
                      child: const DoctorAppointmentScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'caregiver-booking',
                    pageBuilder: (context, state) => kayloPage(
                      state: state,
                      child: const CaregiverBookingScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'medicines', // Routes.careMedicines
                    pageBuilder: (context, state) => kayloPage(
                      state: state,
                      child: const MedicineRemindersScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'sos', // Routes.careSos
                    pageBuilder: (context, state) => kayloPage(
                      state: state,
                      child: const EmergencySosScreen(),
                    ),
                    routes: [
                      GoRoute(
                        path: 'history', // Routes.careSosHistory
                        pageBuilder: (context, state) => kayloPage(
                          state: state,
                          child: const SosHistoryScreen(),
                        ),
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
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: Routes.settings,
                    pageBuilder: (context, state) =>
                        kayloPage(state: state, child: const SettingsScreen()),
                  ),
                  GoRoute(
                    path: 'addresses', // Routes.addresses
                    pageBuilder: (context, state) => kayloPage(
                      state: state,
                      child: const SavedAddressesScreen(),
                    ),
                  ),
                  GoRoute(
                    path: 'help', // Routes.help
                    pageBuilder: (context, state) => kayloPage(
                      state: state,
                      child: const HelpSupportScreen(),
                    ),
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
