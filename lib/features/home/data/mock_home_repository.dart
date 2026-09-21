import '../../../core/models/service_item.dart';
import '../../../core/models/worker.dart';
import '../domain/home_repository.dart';

class MockHomeRepository implements HomeRepository {
  final List<ServiceItem> _mockServices = [
    ServiceItem(id: '1', name: 'Coconut Plucking', category: 'farm', description: 'Professional coconut climbers', iconPath: 'assets_kaylo/3d_transparent/icon_coconut.png', basePrice: 1000, isPopular: true),
    ServiceItem(id: '2', name: 'Arecanut Harvesting', category: 'farm', description: 'Expert harvesting', iconPath: 'assets_kaylo/3d_transparent/icon_arecanut.png', basePrice: 1200, isPopular: true),
    ServiceItem(id: '3', name: 'Gardening', category: 'home', description: 'Lawn and garden maintenance', iconPath: 'assets_kaylo/3d_transparent/icon_garden.png', basePrice: 800, isPopular: true),
    ServiceItem(id: '4', name: 'Plumbing', category: 'home', description: 'Expert plumbing services at your doorstep', iconPath: 'assets_kaylo/3d_transparent/icon_plumb.png', basePrice: 500, isPopular: true),
    ServiceItem(id: '5', name: 'Electrical', category: 'home', description: 'Electrical repairs, wiring, and installations', iconPath: 'assets_kaylo/3d_transparent/icon_electric.png', basePrice: 400, isPopular: true),
    ServiceItem(id: '6', name: 'More', category: 'home', description: 'More services', iconPath: 'assets_kaylo/3d_transparent/icon_more.png', basePrice: 0, isPopular: true),
    ServiceItem(id: '7', name: 'House Cleaning', category: 'home', description: 'Deep cleaning and sanitization services', iconPath: 'assets_kaylo/3d_transparent/mode_home.png', basePrice: 600, isPopular: true),
    ServiceItem(id: '8', name: 'Caregiver Visit', category: 'care', description: 'Trained caregivers for seniors', iconPath: 'assets_kaylo/3d_transparent/mode_care.png', basePrice: 700),
    ServiceItem(id: '9', name: 'Medicine Delivery', category: 'care', description: 'Medicines at your doorstep', iconPath: 'assets_kaylo/3d_transparent/mode_care.png', basePrice: 100),
    ServiceItem(id: '10', name: 'Tree Pruning', category: 'farm', description: 'Overhanging branches trimmed safely near roofs and power lines', iconPath: 'assets_kaylo/3d_transparent/icon_garden.png', basePrice: 600, estimatedDurationMinutes: 90),
    ServiceItem(id: '11', name: 'Plot Clearing', category: 'farm', description: 'Grass and bush cleared with brush cutters', iconPath: 'assets_kaylo/3d_transparent/mode_farm.png', basePrice: 350, estimatedDurationMinutes: 60),
    ServiceItem(id: '12', name: 'Carpentry', category: 'home', description: 'Furniture repair, assembly, and woodwork', iconPath: 'assets_kaylo/3d_transparent/icon_more.png', basePrice: 450),
    ServiceItem(id: '13', name: 'Painting', category: 'home', description: 'Interior and exterior home painting', iconPath: 'assets_kaylo/3d_transparent/icon_more.png', basePrice: 800),
    ServiceItem(id: '14', name: 'AC Service', category: 'home', description: 'AC maintenance, repair, and gas refilling', iconPath: 'assets_kaylo/3d_transparent/icon_more.png', basePrice: 650),
    ServiceItem(id: '15', name: 'Appliance Repair', category: 'home', description: 'Washing machine, fridge, and TV repair', iconPath: 'assets_kaylo/3d_transparent/icon_more.png', basePrice: 500),
  ];

  final List<Worker> _mockWorkers = [
    Worker(id: 'w1', name: 'Raju K.', profileImageUrl: '', rating: 4.8, reviewsCount: 120, skillIds: ['1', '4'], location: 'Kochi', trustScore: 95, isVerified: true, hourlyRate: 350, totalJobs: 132),
    Worker(id: 'w2', name: 'Manoj P.', profileImageUrl: '', rating: 4.5, reviewsCount: 85, skillIds: ['1', '4', '12'], location: 'Ernakulam', trustScore: 88, isVerified: true, hourlyRate: 300, totalJobs: 96),
    Worker(id: 'w3', name: 'Suresh B.', profileImageUrl: '', rating: 4.9, reviewsCount: 200, skillIds: ['5', '14'], location: 'Thrissur', trustScore: 98, isVerified: true, hourlyRate: 400, totalJobs: 214),
    Worker(id: 'w4', name: 'Anil Kumar', profileImageUrl: '', rating: 4.7, reviewsCount: 75, skillIds: ['7', '13'], location: 'Kochi', trustScore: 92, isVerified: true, hourlyRate: 280, totalJobs: 82),
    Worker(id: 'w5', name: 'Prasad V.', profileImageUrl: '', rating: 4.6, reviewsCount: 110, skillIds: ['4', '15'], location: 'Kochi', trustScore: 90, isVerified: false, hourlyRate: 320, totalJobs: 105),
  ];

  @override
  Future<List<ServiceItem>> getPopularServices() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockServices.where((s) => s.isPopular).toList();
  }

  @override
  Future<List<ServiceItem>> getServicesByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockServices.where((s) => s.category == category).toList();
  }

  @override
  Future<ServiceItem?> getServiceById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mockServices.where((s) => s.id == id).firstOrNull;
  }

  @override
  Future<List<ServiceItem>> searchServices(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase().trim();
    return _mockServices.where((s) =>
        s.name.toLowerCase().contains(lower) ||
        s.description.toLowerCase().contains(lower)).toList();
  }

  @override
  Future<List<Worker>> searchWorkers(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase().trim();
    return _mockWorkers.where((w) =>
        w.name.toLowerCase().contains(lower) ||
        w.location.toLowerCase().contains(lower)).toList();
  }
}
