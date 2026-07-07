import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/bookings_repository.dart';
import '../data/mock_bookings_repository.dart';
import '../../home/application/home_providers.dart'; // import useMock

final bookingsRepositoryProvider = Provider<BookingsRepository>((ref) {
  if (useMock) {
    return MockBookingsRepository();
  }
  throw UnimplementedError('Real FirestoreBookingsRepository is not implemented yet.');
});
