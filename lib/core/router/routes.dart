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
  
  // Farm flow: full-screen, outside the tab shell so checkout has no
  // bottom nav competing with its own primary button.
  static const String farm = '/farm';
  static String farmService(String serviceId) => '/farm/$serviceId';
  static String farmSchedule(String serviceId) => '/farm/$serviceId/schedule';
  static String farmPayment(String serviceId) => '/farm/$serviceId/payment';

  // Shared by every booking flow (farm today, home services when M3/M4
  // land theirs). Takes a BookingReceipt as `extra`.
  static const String bookingConfirmation = '/booking/confirmation';

  // One conversation, pushed over the shell.
  static String chat(String threadId) => '/chat/$threadId';

  // Care flows, nested under the Care tab.
  static const String careMedicines = '/care/medicines';
  static const String careSos = '/care/sos';
  static const String careSosHistory = '/care/sos/history';

  // Discovery and booking handoff, pushed over the shell so the bottom
  // nav does not sit under details, worker lists and checkout.
  // serviceDetails takes ?id=, workerList ?serviceId=&serviceName=,
  // workerProfile ?workerId=&serviceId=, bookService ?serviceId=&workerId=.
  static const String homeServices = '/home-services';
  static const String serviceDetails = '/service-details';
  static const String workerList = '/workers';
  static const String workerProfile = '/worker-profile';
  static const String search = '/search';
  static const String bookService = '/book-service';

  // Feature screens
  static const String payment = '/dashboard/payment';
  static const String confirmation = '/dashboard/confirmation';
  static const String tracking = '/dashboard/tracking';
  static const String review = '/dashboard/review';
  static const String farmServices = '/dashboard/farm-services';
  static const String familyDashboard = '/dashboard/family-dashboard';
  static const String settings = 'settings';
  static const String doctorAppointment = '/care/doctor-appointment';
  static const String caregiverBooking = '/care/caregiver-booking';
}
