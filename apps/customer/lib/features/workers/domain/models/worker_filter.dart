enum WorkerSort { rating, priceLowToHigh, priceHighToLow, experience, distance }

class WorkerFilter {
  final double? minRating;
  final double? maxPrice;
  final bool availableToday;
  final bool verifiedOnly;

  const WorkerFilter({
    this.minRating,
    this.maxPrice,
    this.availableToday = false,
    this.verifiedOnly = false,
  });

  WorkerFilter copyWith({
    double? minRating,
    double? maxPrice,
    bool? availableToday,
    bool? verifiedOnly,
  }) {
    return WorkerFilter(
      minRating: minRating ?? this.minRating,
      maxPrice: maxPrice ?? this.maxPrice,
      availableToday: availableToday ?? this.availableToday,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  bool get hasActiveFilters =>
      minRating != null || maxPrice != null || availableToday || verifiedOnly;
}
