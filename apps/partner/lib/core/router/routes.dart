/// Partner app route constants.
///
/// Convention: top-level tabs are full paths (e.g. `/jobs`); every
/// nested route is a *relative* name that the parent GoRoute composes.
class Routes {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';
  static const String apply = '/apply';
  static const String applicationStatus = '/application-status';
  static const String changePassword = '/change-password';
  static const String accountStatus = '/account-status';

  // Bottom-nav shell tabs
  static const String jobs = '/jobs';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String alerts = '/alerts';
  static const String messages = '/messages';
  static const String reviews = '/reviews';
  static String conversation(String jobId) =>
      '/messages/${Uri.encodeComponent(jobId)}';
  static const String availability = '/availability';

  // Job detail – pushed over the shell
  static const String jobMapRoute = '/jobs/:id/map';
  static String jobDetail(String id) => '/jobs/$id';
  static String jobMap(String id) => '/jobs/$id/map';
}
