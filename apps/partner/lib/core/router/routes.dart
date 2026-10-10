/// Partner app route constants.
///
/// Convention: top-level tabs are full paths (e.g. `/jobs`); every
/// nested route is a *relative* name that the parent GoRoute composes.
class Routes {
  // Auth
  static const String splash = '/splash';
  static const String login = '/login';

  // Bottom-nav shell tabs
  static const String jobs = '/jobs';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
  static const String history = '/history';
  static const String availability = '/availability';

  // Job detail – pushed over the shell
  static String jobDetail(String id) => '/jobs/$id';
}
