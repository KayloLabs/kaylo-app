import '../../../core/models/service_item.dart';

abstract class HomeRepository {
  Future<List<ServiceItem>> getPopularServices();
  Future<List<ServiceItem>> getServicesByCategory(String category);
}
