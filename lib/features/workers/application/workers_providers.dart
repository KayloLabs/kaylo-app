import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/workers_repository.dart';
import '../data/mock_workers_repository.dart';
import '../../home/application/home_providers.dart'; // import useMock

final workersRepositoryProvider = Provider<WorkersRepository>((ref) {
  if (useMock) {
    return MockWorkersRepository();
  }
  throw UnimplementedError('Real FirestoreWorkersRepository is not implemented yet.');
});
