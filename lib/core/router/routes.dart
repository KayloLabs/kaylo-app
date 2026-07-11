class Routes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otp = '/otp';
  static const String location = '/location';
  
  // Dev Routes
  static const String widgetbook = '/dev/widgetbook';
  
  // Dashboard Tabs (ShellRoute)
  static const String dashboard = '/dashboard'; // default tab (home)
  static const String bookings = '/bookings';
  static const String careHome = '/care';
  static const String messages = '/messages';
  static const String profile = '/profile';
  
  // Feature screens
  static const String serviceDetails = 'service-details'; // relative to dashboard tab
  static const String workerList = 'workers';
  static const String bookService = 'book-service';
  static const String payment = 'payment';
  static const String confirmation = 'confirmation';
  static const String tracking = 'tracking';
  static const String review = 'review';
  static const String farmServices = 'farm-services';
  static const String familyDashboard = 'family-dashboard';
  static const String settings = 'settings';
}
