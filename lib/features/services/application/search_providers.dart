import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service_item.dart';
import '../../home/application/home_providers.dart';
import '../../home/application/voice_search.dart';

enum SearchSort { relevance, priceLowHigh, priceHighLow }

/// What the search screen is showing; a record so it works as a family
/// key with value equality.
typedef SearchQuery = ({String text, String? category, SearchSort sort});

const SearchQuery emptySearch =
    (text: '', category: null, sort: SearchSort.relevance);

/// Text search over the catalog. Direct name/description matches rank
/// first; the voice-search intent engine then adds natural-language hits
/// ("tap is leaking" finds Plumbing) in any of the four languages.
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<ServiceItem>, SearchQuery>((ref, query) async {
  final catalog = await ref.watch(fullCatalogProvider.future);
  // The "More" tile is a dashboard affordance, not a bookable service.
  var pool = catalog.where((s) => s.basePrice > 0).toList();
  if (query.category != null) {
    pool = pool.where((s) => s.category == query.category).toList();
  }

  final text = query.text.trim().toLowerCase();
  List<ServiceItem> results;
  if (text.isEmpty) {
    results = pool;
  } else {
    final direct = pool
        .where((s) =>
            s.name.toLowerCase().contains(text) ||
            s.description.toLowerCase().contains(text))
        .toList();
    final seen = {for (final s in direct) s.id};
    results = [
      ...direct,
      for (final s in matchServicesToTranscript(text, pool))
        if (seen.add(s.id)) s,
    ];
  }

  switch (query.sort) {
    case SearchSort.priceLowHigh:
      results = [...results]..sort((a, b) => a.basePrice.compareTo(b.basePrice));
    case SearchSort.priceHighLow:
      results = [...results]..sort((a, b) => b.basePrice.compareTo(a.basePrice));
    case SearchSort.relevance:
      break;
  }
  return results;
});
