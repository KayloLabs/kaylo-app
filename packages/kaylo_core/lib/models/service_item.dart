class ServiceItem {
  final String id;
  final String name;
  final String category; // e.g. "home", "farm", "care"
  final String description;
  final String iconPath; // asset path or network URL
  final double basePrice;
  final bool isPopular;

  /// Mirrors `services.estimated_duration_minutes`; null when unknown.
  final int? estimatedDurationMinutes;

  ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.iconPath,
    required this.basePrice,
    this.isPopular = false,
    this.estimatedDurationMinutes,
  });
}
