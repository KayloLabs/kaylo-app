import 'app_failure.dart';
// import 'package:firebase_core/firebase_core.dart';

class ErrorMapper {
  static AppFailure map(Object error, [StackTrace? stackTrace]) {
    // If we're already an AppFailure, just return it
    if (error is AppFailure) {
      return error;
    }

    // Fallback for unexpected errors
    return ServerFailure(
      'An unexpected error occurred.',
      code: 'unknown',
      originalError: error,
    );
  }
}
