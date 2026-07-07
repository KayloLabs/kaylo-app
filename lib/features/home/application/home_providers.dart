import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/home_repository.dart';
import '../data/mock_home_repository.dart';

const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  if (useMock) {
    return MockHomeRepository();
  }
  // TODO: Return Real FirestoreHomeRepository here
  // return FirestoreHomeRepository();
  throw UnimplementedError('Real FirestoreHomeRepository is not implemented yet. Use --dart-define=USE_MOCK=true');
});
