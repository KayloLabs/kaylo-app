/// Partner app route constants.
///
/// Convention: top-level tabs are full paths (e.g. `/jobs`); every
/// nested route is a *relative* name that the parent GoRoute composes.
class Routes {
  // Auth
  static const String login = '/login';

  // Bottom-nav shell tabs
  static const String jobs = '/jobs';
  static const String earnings = '/earnings';
  static const String profile = '/profile';
  static const String history = '/history';

  // Job detail – pushed over the shell
  static const String jobMapRoute = '/jobs/:id/map';
  static String jobDetail(String id) => '/jobs/$id';
  static String jobMap(String id) => '/jobs/$id/map';
}
