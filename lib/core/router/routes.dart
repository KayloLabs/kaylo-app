class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String loginOtp = '/login/otp';
  static const String location = '/location';

  // Dev Routes
  static const String widgetbook = '/dev/widgetbook';

  // Dashboard Tabs (ShellRoute)
  static const String dashboard = '/dashboard'; // default tab (home)
  static const String bookings = '/bookings';
  static const String careHome = '/care';
  static const String messages = '/messages';
  static const String profile = '/profile';

  // Discovery: a category list ('home', 'farm', 'care' or 'all') and
  // search, both full-screen over the shell.
  static String services(String category) => '/services/$category';
  static const String search = '/search';

  // Booking flow for any service: details -> schedule -> payment ->
  // confirmation. Full-screen so checkout owns the bottom edge.
  static String service(String serviceId) => '/service/$serviceId';
  static String serviceSchedule(String serviceId) =>
      '/service/$serviceId/schedule';
  static String servicePayment(String serviceId) =>
      '/service/$serviceId/payment';
  static const String bookingConfirmation = '/booking/confirmation';

  // One booking, nested under the Bookings tab.
  static String bookingDetails(String bookingId) => '/bookings/$bookingId';

  static const String notifications = '/notifications';

  // One conversation, pushed over the shell.
  static String chat(String threadId) => '/chat/$threadId';

  // Care flows, nested under the Care tab.
  static const String careMedicines = '/care/medicines';
  static const String careSos = '/care/sos';
  static const String careSosHistory = '/care/sos/history';

  // Profile flows, nested under the Profile tab.
  static const String addresses = '/profile/addresses';
  static const String help = '/profile/help';
  static const String settings = 'settings'; // relative to profile

  // Reserved for M3/M4 screens, relative to their parent tab.
  static const String workerList = 'workers';
  static const String tracking = 'tracking';
  static const String review = 'review';
  static const String familyDashboard = 'family-dashboard';
}
