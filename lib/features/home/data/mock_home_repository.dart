import '../../../core/models/service_item.dart';
import '../domain/home_repository.dart';

class MockHomeRepository implements HomeRepository {
  final List<ServiceItem> _mockServices = [
    ServiceItem(id: '1', name: 'Coconut Plucking', category: 'farm', description: 'Professional coconut climbers', iconPath: 'assets_kaylo/3d_transparent/icon_coconut.png', basePrice: 1000, isPopular: true),
    ServiceItem(id: '2', name: 'Arecanut Harvesting', category: 'farm', description: 'Expert harvesting', iconPath: 'assets_kaylo/3d_transparent/icon_arecanut.png', basePrice: 1200, isPopular: true),
    ServiceItem(id: '3', name: 'Gardening', category: 'home', description: 'Lawn and garden maintenance', iconPath: 'assets_kaylo/3d_transparent/icon_garden.png', basePrice: 800, isPopular: true),
    ServiceItem(id: '4', name: 'Plumbing', category: 'home', description: 'Expert plumbing services', iconPath: 'assets_kaylo/3d_transparent/icon_plumb.png', basePrice: 500, isPopular: true),
    ServiceItem(id: '5', name: 'Electrical', category: 'home', description: 'Electrical repairs and wiring', iconPath: 'assets_kaylo/3d_transparent/icon_electric.png', basePrice: 400, isPopular: true),
    ServiceItem(id: '6', name: 'More', category: 'home', description: 'More services', iconPath: 'assets_kaylo/3d_transparent/icon_more.png', basePrice: 0, isPopular: true),
  ];

  @override
  Future<List<ServiceItem>> getPopularServices() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    return _mockServices.where((s) => s.isPopular).toList();
  }

  @override
  Future<List<ServiceItem>> getServicesByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    return _mockServices.where((s) => s.category == category).toList();
  }
}
