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

  const SearchResults({this.services = const [], this.workers = const []});

  bool get isEmpty => services.isEmpty && workers.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class SearchState {
  final String query;
  final SearchFilters filters;
  final SearchResults results;
  final List<String> recentSearches;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.filters = noFilters,
    this.results = const SearchResults(),
    this.recentSearches = const [],
    this.isLoading = false,
  });

  /// Whether there is something to show results for: typed text, or a
  /// category picked from the filters, which browses that category.
  bool get hasQuery => query.trim().isNotEmpty || filters.category != null;

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    SearchResults? results,
    List<String>? recentSearches,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
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
    ref.onDispose(() => _debounceTimer?.cancel());
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

    if (newQuery.trim().isEmpty && state.filters.category == null) {
      _generation++;
      state = state.copyWith(
        query: '',
        results: const SearchResults(),
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(query: newQuery, isLoading: true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), _performSearch);
  }

  void setFilters(SearchFilters filters) {
    _debounceTimer?.cancel();
    state = state.copyWith(filters: filters);
    if (!state.hasQuery) {
      _generation++;
      state = state.copyWith(results: const SearchResults(), isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true);
    _performSearch();
  }

  void clearFilters() => setFilters(noFilters);

  Future<void> _performSearch() async {
    final generation = ++_generation;
    final query = state.query.trim();
    final filters = state.filters;
    final homeRepo = ref.read(homeRepositoryProvider);
    final workersRepo = ref.read(workersRepositoryProvider);
    try {
      final catalogFuture = ref.read(fullCatalogProvider.future);
      final directFuture = query.isEmpty
          ? Future.value(const <ServiceItem>[])
          : homeRepo.searchServices(query);
      final workersFuture = query.isEmpty
          ? Future.value(const <Worker>[])
          : workersRepo.searchWorkers(query);

      final catalog = await catalogFuture;
      final direct = await directFuture;
      final workers = await workersFuture;
      if (generation != _generation) return;

      state = state.copyWith(
        results: SearchResults(
          services: _rankServices(query, filters, direct, catalog),
          workers: workers,
        ),
        isLoading: false,
      );
    } catch (_) {
      if (generation == _generation) {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  /// Direct name/description matches first, then the voice-search
  /// intent engine's natural-language hits ("tap is leaking" finds
  /// Plumbing) in any of the four languages; an empty query browses the
  /// chosen category.
  List<ServiceItem> _rankServices(
    String query,
    SearchFilters filters,
    List<ServiceItem> direct,
    List<ServiceItem> catalog,
  ) {
    // "More" is a dashboard affordance, not a bookable service.
    var pool = catalog.where((s) => s.basePrice > 0).toList();
    if (filters.category != null) {
      pool = pool.where((s) => s.category == filters.category).toList();
    }
    final allowed = {for (final s in pool) s.id};

    List<ServiceItem> results;
    if (query.isEmpty) {
      results = pool;
    } else {
      final seen = <String>{};
      results = [
        for (final s in direct)
          if (allowed.contains(s.id) && seen.add(s.id)) s,
        for (final s in matchServicesToTranscript(query, pool))
          if (seen.add(s.id)) s,
      ];
    }

    switch (filters.sort) {
      case SearchSort.priceLowHigh:
        results = [...results]
          ..sort((a, b) => a.basePrice.compareTo(b.basePrice));
      case SearchSort.priceHighLow:
        results = [...results]
          ..sort((a, b) => b.basePrice.compareTo(a.basePrice));
      case SearchSort.relevance:
        break;
    }
    return results;
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

/// Lives as long as the search screen, so each visit starts blank
/// instead of showing a previous visit's results under an empty field.
final searchControllerProvider =
    NotifierProvider.autoDispose<SearchNotifier, SearchState>(
      SearchNotifier.new,
    );
