import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/worker.dart';
import '../../../core/network/app_failure.dart';
import '../../../core/network/supabase_providers.dart';
import '../domain/workers_repository.dart';

/// Reads worker listings from the `worker_profiles` view (worker joined
/// with person, skills array, review count and computed trust score).
class SupabaseWorkersRepository implements WorkersRepository {
  final SupabaseClient _client;

  SupabaseWorkersRepository(this._client);

  @override
  Future<List<Worker>> getWorkersByServiceId(String serviceId) async {
    try {
      final rows = await _client
          .from('worker_profiles')
          .select()
          .contains('skill_ids', [serviceId])
          .eq('is_available', true)
          .order('average_rating', ascending: false);
      return rows.map(_workerFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<Worker> getWorkerById(String workerId) async {
    try {
      final row = await _client
          .from('worker_profiles')
          .select()
          .eq('worker_id', workerId)
          .maybeSingle();
      if (row == null) {
        throw ServerFailure('Worker not found', code: 'not-found');
      }
      return _workerFromRow(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  Worker _workerFromRow(Map<String, dynamic> row) {
    return Worker(
      id: row['worker_id'] as String,
      name: row['full_name'] as String,
      profileImageUrl: (row['profile_photo'] as String?) ?? '',
      rating: ((row['average_rating'] as num?) ?? 0).toDouble(),
      reviewsCount: ((row['reviews_count'] as num?) ?? 0).toInt(),
      skillIds: List<String>.from((row['skill_ids'] as List?) ?? const []),
      location: (row['district'] as String?) ?? '',
      trustScore: ((row['trust_score'] as num?) ?? 0).toDouble(),
      isVerified: (row['is_verified'] as bool?) ?? false,
      isAvailable: (row['is_available'] as bool?) ?? true,
      hourlyRate: (row['hourly_rate'] as num?)?.toDouble(),
      totalJobs: ((row['total_jobs'] as num?) ?? 0).toInt(),
    );
  }
}
