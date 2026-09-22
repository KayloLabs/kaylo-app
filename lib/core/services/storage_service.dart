import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> removeToken();

  Future<void> setCareMode(bool enabled);
  Future<bool> getCareMode();

  Future<void> setOnboardingSeen(bool seen);
  Future<bool> getOnboardingSeen();

  Future<void> saveLanguageCode(String code);
  Future<String?> getLanguageCode();

  Future<void> saveThemeMode(String mode); // 'system' | 'light' | 'dark'
  Future<String?> getThemeMode();

  /// JSON of the customer's active location (see UserLocation).
  Future<void> saveActiveLocation(String json);
  Future<String?> getActiveLocation();

  /// JSON list of saved addresses, for the mock addresses repository.
  Future<void> saveAddresses(String json);
  Future<String?> getAddresses();

  /// In-app rating (1 to 5), null until the user rates.
  Future<void> saveAppRating(int stars);
  Future<int?> getAppRating();
}

class SharedPreferencesStorageService implements StorageService {
  final SharedPreferences _prefs;

  SharedPreferencesStorageService(this._prefs);

  static const _tokenKey = 'auth_token';
  static const _careModeKey = 'care_mode';
  static const _onboardingKey = 'onboarding_seen';
  static const _languageKey = 'language_code';
  static const _themeModeKey = 'theme_mode';
  static const _activeLocationKey = 'active_location';
  static const _addressesKey = 'saved_addresses';
  static const _appRatingKey = 'app_rating';

  @override
  Future<String?> getToken() async => _prefs.getString(_tokenKey);

  @override
  Future<void> saveToken(String token) async =>
      await _prefs.setString(_tokenKey, token);

  @override
  Future<void> removeToken() async => await _prefs.remove(_tokenKey);

  @override
  Future<bool> getCareMode() async => _prefs.getBool(_careModeKey) ?? false;

  @override
  Future<void> setCareMode(bool enabled) async =>
      await _prefs.setBool(_careModeKey, enabled);

  @override
  Future<bool> getOnboardingSeen() async =>
      _prefs.getBool(_onboardingKey) ?? false;

  @override
  Future<void> setOnboardingSeen(bool seen) async =>
      await _prefs.setBool(_onboardingKey, seen);

  @override
  Future<String?> getLanguageCode() async => _prefs.getString(_languageKey);

  @override
  Future<void> saveLanguageCode(String code) async =>
      await _prefs.setString(_languageKey, code);

  @override
  Future<String?> getThemeMode() async => _prefs.getString(_themeModeKey);

  @override
  Future<void> saveThemeMode(String mode) async =>
      await _prefs.setString(_themeModeKey, mode);

  @override
  Future<String?> getActiveLocation() async =>
      _prefs.getString(_activeLocationKey);

  @override
  Future<void> saveActiveLocation(String json) async =>
      await _prefs.setString(_activeLocationKey, json);

  @override
  Future<String?> getAddresses() async => _prefs.getString(_addressesKey);

  @override
  Future<void> saveAddresses(String json) async =>
      await _prefs.setString(_addressesKey, json);

  @override
  Future<int?> getAppRating() async => _prefs.getInt(_appRatingKey);

  @override
  Future<void> saveAppRating(int stars) async =>
      await _prefs.setInt(_appRatingKey, stars);
}

// Provider needs to be overridden in main.dart after SharedPreferences.getInstance()
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize sharedPreferencesProvider in main.dart');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return SharedPreferencesStorageService(ref.watch(sharedPreferencesProvider));
});
