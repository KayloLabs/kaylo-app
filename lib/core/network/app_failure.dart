abstract class AppFailure {
  final String message;
  final String? code;
  final Object? originalError;

  AppFailure(this.message, {this.code, this.originalError});
  
  @override
  String toString() => 'AppFailure: $message (code: $code)';
}

class NetworkFailure extends AppFailure {
  NetworkFailure(super.message, {super.code, super.originalError});
}

class ServerFailure extends AppFailure {
  ServerFailure(super.message, {super.code, super.originalError});
}

class CacheFailure extends AppFailure {
  CacheFailure(super.message, {super.code, super.originalError});
}
