import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the user's active location (e.g. "Kochi, Kerala").
/// Defaults to "Kochi, Kerala" and is updated when the user selects a location.
class ActiveLocationNotifier extends Notifier<String> {
  @override
  String build() {
    return 'Kochi, Kerala';
  }

  void setLocation(String location) {
    state = location;
  }
}

final activeLocationProvider =
    NotifierProvider<ActiveLocationNotifier, String>(ActiveLocationNotifier.new);
