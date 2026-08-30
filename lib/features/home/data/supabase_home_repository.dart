import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/service_item.dart';
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
}
