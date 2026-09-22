import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/models/app_user.dart';
import 'session_controller.dart';

/// The signed-in user, or null while the session is loading or absent.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(sessionControllerProvider).whenOrNull(data: (user) => user);
});

/// Convenience for repositories that only need the id.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});
