import 'package:kaylo_core/models/service_item.dart';

abstract class HomeRepository {
  Future<List<ServiceItem>> getPopularServices();
  Future<List<ServiceItem>> getServicesByCategory(String category);
  Future<ServiceItem?> getServiceById(String id);
  Future<List<ServiceItem>> searchServices(String query);
}
