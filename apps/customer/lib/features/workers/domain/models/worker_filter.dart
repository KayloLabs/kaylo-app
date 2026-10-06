enum WorkerSort { rating, priceLowToHigh, priceHighToLow, experience, distance }

const _unchanged = Object();

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
    Object? minRating = _unchanged,
    Object? maxPrice = _unchanged,
    bool? availableToday,
    bool? verifiedOnly,
  }) {
    return WorkerFilter(
      minRating: identical(minRating, _unchanged)
          ? this.minRating
          : (minRating as num?)?.toDouble(),
      maxPrice: identical(maxPrice, _unchanged)
          ? this.maxPrice
          : (maxPrice as num?)?.toDouble(),
      availableToday: availableToday ?? this.availableToday,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  bool get hasActiveFilters =>
      minRating != null || maxPrice != null || availableToday || verifiedOnly;
}
