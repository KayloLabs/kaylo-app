import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kaylo_core/models/service_item.dart';
import 'package:kaylo_core/models/worker.dart';
import 'package:kaylo_core/services/storage_service.dart';
import '../../workers/application/workers_providers.dart';
import 'home_providers.dart';
import 'voice_search.dart';

enum SearchSort { relevance, priceLowHigh, priceHighLow }

/// Narrowing applied on top of the typed query: one category (or all)
/// and a price order. A record so it has value equality.
typedef SearchFilters = ({String? category, SearchSort sort});

const SearchFilters noFilters = (category: null, sort: SearchSort.relevance);

bool filtersActive(SearchFilters filters) =>
    filters.category != null || filters.sort != SearchSort.relevance;

class SearchResults {
  final List<ServiceItem> services;
  final List<Worker> workers;
  final Map<String, String> workerServiceIds;

  const SearchResults({
    this.services = const [],
    this.workers = const [],
    this.workerServiceIds = const {},
  });

  bool get isEmpty => services.isEmpty && workers.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class SearchState {
  final String query;
  final SearchFilters filters;
  final SearchResults results;
  final List<String> recentSearches;
  final bool isLoading;
  final bool hasError;

  const SearchState({
    this.query = '',
    this.filters = noFilters,
    this.results = const SearchResults(),
    this.recentSearches = const [],
    this.isLoading = false,
    this.hasError = false,
  });

  /// Whether there is something to show results for: typed text, or a
  /// category picked from the filters, which browses that category.
  bool get hasQuery => query.trim().isNotEmpty || filtersActive(filters);

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    SearchResults? results,
    List<String>? recentSearches,
    bool? isLoading,
    bool? hasError,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;

  /// Bumped per search so a slow earlier request cannot overwrite the
  /// results of a later one.
  int _generation = 0;
  static const _recentSearchesKey = 'kaylo_recent_searches';

  @override
  SearchState build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _generation++;
    });
    _loadRecentSearches();
    return const SearchState();
  }

  Future<void> _loadRecentSearches() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final recents = prefs.getStringList(_recentSearchesKey) ?? [];
      state = state.copyWith(recentSearches: recents);
    } catch (_) {}
  }

  Future<void> _saveRecentSearches(List<String> recents) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setStringList(_recentSearchesKey, recents);
    } catch (_) {}
  }

  void onQueryChanged(String newQuery) {
    _debounceTimer?.cancel();
    _generation++;

    if (newQuery.trim().isEmpty && !filtersActive(state.filters)) {
      _generation++;
      state = state.copyWith(
        query: '',
        results: const SearchResults(),
        isLoading: false,
        hasError: false,
      );
      return;
    }

    state = state.copyWith(query: newQuery, isLoading: true, hasError: false);

    _debounceTimer = Timer(const Duration(milliseconds: 300), _performSearch);
  }

  void setFilters(SearchFilters filters) {
    _debounceTimer?.cancel();
    _generation++;
    state = state.copyWith(filters: filters, hasError: false);
    if (!state.hasQuery) {
      _generation++;
      state = state.copyWith(results: const SearchResults(), isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    _performSearch();
  }

  void clearFilters() => setFilters(noFilters);

  void retry() {
    if (!state.hasQuery) return;
    ref.invalidate(fullCatalogProvider);
    ref.invalidate(workerListProvider);
    state = state.copyWith(isLoading: true, hasError: false);
    _performSearch();
  }

  Future<void> _performSearch() async {
    final generation = ++_generation;
    final query = state.query.trim();
    final filters = state.filters;
    final workersRepo = ref.read(workersRepositoryProvider);
    var workerError = false;
    Future<List<Worker>> readWorkers(Future<List<Worker>> future) async {
      try {
        return await future;
      } catch (_) {
        workerError = true;
        return const [];
      }
    }

    // The catalog is already cached; avoid an extra database substring
    // query that disagrees with voice matching and depends on network speed.
    final namedWorkers = query.isEmpty
        ? Future.value(const <Worker>[])
        : readWorkers(workersRepo.searchWorkers(query));
    try {
      final catalog = await ref.read(fullCatalogProvider.future);
      if (generation != _generation) return;
      final services = rankSearchServices(query, filters, catalog);
      final bySkill = query.isEmpty
          ? const <List<Worker>>[]
          : await Future.wait([
              for (final service in services)
                readWorkers(ref.read(workerListProvider(service.id).future)),
            ]);
      final directWorkers = await namedWorkers;
      if (generation != _generation) return;
      final workers = rankSearchWorkers(
        [...directWorkers, for (final list in bySkill) ...list],
        filters,
        catalog,
      );
      final skillChoices = [
        ...services.map((service) => service.id),
        ...catalog
            .where(
              (service) =>
                  filters.category == null ||
                  service.category == filters.category,
            )
            .map((service) => service.id),
      ];
      state = state.copyWith(
        results: SearchResults(
          services: services,
          workers: workers,
          workerServiceIds: {
            for (final worker in workers)
              if (skillChoices.any(worker.skillIds.contains))
                worker.id: skillChoices.firstWhere(worker.skillIds.contains),
          },
        ),
        isLoading: false,
        hasError: workerError,
      );
    } catch (_) {
      if (generation == _generation) {
        state = state.copyWith(
          results: const SearchResults(),
          isLoading: false,
          hasError: true,
        );
      }
    }
  }

  Future<void> addRecentSearch(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;

    final current = List<String>.from(state.recentSearches);
    current.remove(trimmed);
    current.insert(0, trimmed);
    if (current.length > 8) {
      current.removeLast();
    }

    state = state.copyWith(recentSearches: current);
    await _saveRecentSearches(current);
  }

  Future<void> removeRecentSearch(String term) async {
    final current = List<String>.from(state.recentSearches);
    current.remove(term);
    state = state.copyWith(recentSearches: current);
    await _saveRecentSearches(current);
  }

  Future<void> clearRecentSearches() async {
    state = state.copyWith(recentSearches: const []);
    await _saveRecentSearches(const []);
  }
}

/// One relevance engine for text, voice, and popular-search chips. Price
/// order applies after relevance/category narrowing and has stable ties.
List<ServiceItem> rankSearchServices(
  String query,
  SearchFilters filters,
  List<ServiceItem> catalog,
) {
  final pool = catalog
      .where(
        (service) =>
            service.name.toLowerCase() != 'more' &&
            (filters.category == null || service.category == filters.category),
      )
      .toList();
  final results = query.trim().isEmpty
      ? pool
      : matchServicesToTranscript(query, pool);
  if (filters.sort != SearchSort.relevance) {
    results.sort((a, b) {
      final price = filters.sort == SearchSort.priceLowHigh
          ? a.basePrice.compareTo(b.basePrice)
          : b.basePrice.compareTo(a.basePrice);
      return price != 0 ? price : a.name.compareTo(b.name);
    });
  }
  return results;
}

List<Worker> rankSearchWorkers(
  List<Worker> workers,
  SearchFilters filters,
  List<ServiceItem> catalog,
) {
  final allowedSkills = {
    for (final service in catalog)
      if (filters.category == null || service.category == filters.category)
        service.id,
  };
  final seen = <String>{};
  final results = workers
      .where(
        (worker) =>
            worker.isAvailable &&
            seen.add(worker.id) &&
            (filters.category == null ||
                worker.skillIds.any(allowedSkills.contains)),
      )
      .toList();
  results.sort((a, b) {
    if (filters.sort != SearchSort.relevance) {
      // Unknown prices are never presented as free or sorted ahead of
      // known rates, in either direction.
      if (a.hourlyRate == null && b.hourlyRate != null) return 1;
      if (a.hourlyRate != null && b.hourlyRate == null) return -1;
      if (a.hourlyRate != null && b.hourlyRate != null) {
        final price = filters.sort == SearchSort.priceLowHigh
            ? a.hourlyRate!.compareTo(b.hourlyRate!)
            : b.hourlyRate!.compareTo(a.hourlyRate!);
        if (price != 0) return price;
      }
    }
    final rating = b.rating.compareTo(a.rating);
    if (rating != 0) return rating;
    final name = a.name.compareTo(b.name);
    return name != 0 ? name : a.id.compareTo(b.id);
  });
  return results;
}

/// Lives as long as the search screen, so each visit starts blank
/// instead of showing a previous visit's results under an empty field.
final searchControllerProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchState>(
      SearchNotifier.new,
    );
