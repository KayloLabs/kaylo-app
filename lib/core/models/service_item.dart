class ServiceItem {
  final String id;
  final String name;
  final String category; // e.g. "home", "farm", "care"
  final String description;
  final String iconPath; // asset path or network URL
  final double basePrice;
  final bool isPopular;

  ServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.iconPath,
    required this.basePrice,
    this.isPopular = false,
  });
}
