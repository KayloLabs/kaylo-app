import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/models/app_user.dart';
import '../domain/auth_repository.dart';

part 'session_controller.g.dart';

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  late final AuthRepository _authRepo;
  StreamSubscription<AppUser?>? _subscription;

  @override
  FutureOr<AppUser?> build() async {
    _authRepo = ref.watch(authRepositoryProvider);
    
    // Listen to changes in auth state and update this provider's state
    _subscription = _authRepo.authStateChanges.listen((user) {
      state = AsyncData(user);
    });

    // Return current user initially
    return _authRepo.currentUser;
  }
  
  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _authRepo.signOut();
      // State is updated via the stream listener
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
