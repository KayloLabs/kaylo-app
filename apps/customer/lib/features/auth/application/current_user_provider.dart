import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/models/app_user.dart';
import 'session_controller.dart';

/// The signed-in user, or null while the session is loading or absent.
final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(sessionControllerProvider).whenOrNull(data: (user) => user);
});

/// Waits for the session to produce a signed-in user. After Firebase
/// accepts the code the profile still takes a few round trips to load,
/// longer on a phone, and a screen that navigates before it arrives is
/// sent back to login by the router. Gives up after about [timeout].
Future<AppUser?> awaitSignedInUser(
  WidgetRef ref, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  const step = Duration(milliseconds: 150);
  var tries = timeout.inMilliseconds ~/ step.inMilliseconds;
  var user = ref.read(currentUserProvider);
  while (user == null && tries-- > 0) {
    await Future<void>.delayed(step);
    user = ref.read(currentUserProvider);
  }
  return user;
}

/// Convenience for repositories that only need the id.
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});
