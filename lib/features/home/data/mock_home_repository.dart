import '../../../core/models/service_item.dart';
import '../domain/home_repository.dart';

class MockHomeRepository implements HomeRepository {
  final List<ServiceItem> _mockServices = [
    ServiceItem(id: '1', name: 'Plumbing', category: 'home', description: 'Expert plumbing services', iconPath: 'assets/icons/plumbing.png', basePrice: 500, isPopular: true),
    ServiceItem(id: '2', name: 'Electrical', category: 'home', description: 'Electrical repairs and wiring', iconPath: 'assets/icons/electrical.png', basePrice: 400, isPopular: true),
    ServiceItem(id: '3', name: 'Cleaning', category: 'home', description: 'Deep house cleaning', iconPath: 'assets/icons/cleaning.png', basePrice: 1500, isPopular: true),
    ServiceItem(id: '4', name: 'AC Service', category: 'home', description: 'AC repair and maintenance', iconPath: 'assets/icons/ac.png', basePrice: 600, isPopular: true),
    ServiceItem(id: '5', name: 'Coconut Harvesting', category: 'farm', description: 'Professional coconut climbers', iconPath: 'assets/icons/coconut.png', basePrice: 1000, isPopular: false),
    ServiceItem(id: '6', name: 'Gardening', category: 'farm', description: 'Lawn and garden maintenance', iconPath: 'assets/icons/garden.png', basePrice: 800, isPopular: false),
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
