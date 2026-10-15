import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/network/app_failure.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import '../domain/models/worker_review.dart';
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
          .eq('is_bookable', true)
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

  @override
  Future<List<Worker>> searchWorkers(String query) async {
    final term = query
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N} ]', unicode: true), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (term.isEmpty) return [];
    try {
      final rows = await _client
          .from('worker_profiles')
          .select()
          .or('full_name.ilike.%$term%,district.ilike.%$term%')
          .eq('is_bookable', true)
          .order('average_rating', ascending: false);
      return rows.map(_workerFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<WorkerReview>> getReviewsForWorker(String workerId) async {
    try {
      final result = await _client.rpc('public_worker_reviews', params: {'p_worker_id': workerId});
      final rows = (result as List).cast<Map<String, dynamic>>();
      return rows.map((r) {
        final customerName = r['customer_name'] as String? ?? 'Verified customer';
        return WorkerReview(
          id: r['review_id'] as String,
          workerId: r['worker_id'] as String,
          customerName: customerName,
          rating: ((r['rating'] as num?) ?? 5).toDouble(),
          comment: (r['review'] as String?) ?? '',
          createdAt:
              DateTime.tryParse(r['created_at'] as String? ?? '') ??
              DateTime.now(),
        );
      }).toList();
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
      isAvailable: (row['is_available'] as bool?) ?? false,
      hourlyRate: (row['hourly_rate'] as num?)?.toDouble(),
      totalJobs: ((row['total_jobs'] as num?) ?? 0).toInt(),
    );
  }
}
