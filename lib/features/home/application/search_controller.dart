import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/service_item.dart';
import '../../../core/models/worker.dart';
import '../../../core/services/storage_service.dart';
import 'home_providers.dart';

class SearchResults {
  final List<ServiceItem> services;
  final List<Worker> workers;

  const SearchResults({
    this.services = const [],
    this.workers = const [],
  });

  bool get isEmpty => services.isEmpty && workers.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

class SearchState {
  final String query;
  final SearchResults results;
  final List<String> recentSearches;
  final bool isLoading;

  const SearchState({
    this.query = '',
    this.results = const SearchResults(),
    this.recentSearches = const [],
    this.isLoading = false,
  });

  SearchState copyWith({
    String? query,
    SearchResults? results,
    List<String>? recentSearches,
    bool? isLoading,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      recentSearches: recentSearches ?? this.recentSearches,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  Timer? _debounceTimer;
  static const _recentSearchesKey = 'kaylo_recent_searches';

  @override
  SearchState build() {
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

    if (newQuery.trim().isEmpty) {
      state = state.copyWith(
        query: '',
        results: const SearchResults(),
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(query: newQuery, isLoading: true);

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await _performSearch(newQuery);
    });
  }

  Future<void> _performSearch(String query) async {
    final homeRepo = ref.read(homeRepositoryProvider);
    try {
      final servicesFuture = homeRepo.searchServices(query);
      final workersFuture = homeRepo.searchWorkers(query);

      final results = await Future.wait([servicesFuture, workersFuture]);
      final services = results[0] as List<ServiceItem>;
      final workers = results[1] as List<Worker>;

      state = state.copyWith(
        results: SearchResults(services: services, workers: workers),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
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

final searchControllerProvider =
    NotifierProvider<SearchNotifier, SearchState>(SearchNotifier.new);
