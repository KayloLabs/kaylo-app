import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/service_item.dart';
import '../../../core/models/worker.dart';
import '../../../core/network/supabase_providers.dart';
import '../domain/home_repository.dart';

/// Reads the service catalog from the `service_catalog` view
/// (services joined with their category slug).
class SupabaseHomeRepository implements HomeRepository {
  final SupabaseClient _client;

  SupabaseHomeRepository(this._client);

  @override
  Future<List<ServiceItem>> getPopularServices() async {
    try {
      final rows = await _client
          .from('service_catalog')
          .select()
          .eq('is_popular', true)
          .order('service_name', ascending: true);
      return rows.map(_serviceFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<ServiceItem>> getServicesByCategory(String category) async {
    try {
      final rows = await _client
          .from('service_catalog')
          .select()
          .eq('category_slug', category)
          .order('service_name', ascending: true);
      return rows.map(_serviceFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<ServiceItem?> getServiceById(String id) async {
    try {
      final row = await _client
          .from('service_catalog')
          .select()
          .eq('service_id', id)
          .maybeSingle();
      if (row == null) return null;
      return _serviceFromRow(row);
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<ServiceItem>> searchServices(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final rows = await _client
          .from('service_catalog')
          .select()
          .ilike('service_name', '%$query%')
          .order('service_name', ascending: true);
      return rows.map(_serviceFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  @override
  Future<List<Worker>> searchWorkers(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final rows = await _client
          .from('worker_profiles')
          .select()
          .ilike('full_name', '%$query%')
          .order('average_rating', ascending: false);
      return rows.map(_workerFromRow).toList();
    } catch (e) {
      throw mapSupabaseError(e);
    }
  }

  ServiceItem _serviceFromRow(Map<String, dynamic> row) {
    return ServiceItem(
      id: row['service_id'] as String,
      name: row['service_name'] as String,
      category: row['category_slug'] as String,
      description: (row['description'] as String?) ?? '',
      iconPath: (row['icon_path'] as String?) ?? '',
      basePrice: ((row['base_price'] as num?) ?? 0).toDouble(),
      isPopular: (row['is_popular'] as bool?) ?? false,
      estimatedDurationMinutes:
          (row['estimated_duration_minutes'] as num?)?.toInt(),
    );
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
