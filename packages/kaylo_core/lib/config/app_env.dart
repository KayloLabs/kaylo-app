/// Compile-time environment for Kaylo.
///
/// Run with mocks (no backend needed):
///   flutter run -d chrome --dart-define=USE_MOCK=true
///
/// Run against Supabase:
///   flutter run -d chrome \
///     --dart-define=SUPABASE_URL=https://PROJECT.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=YOUR_KEY
library;

const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: false);

const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

const bool supabaseConfigured = supabaseUrl != '' && supabaseAnonKey != '';

/// Web OAuth client id of the Firebase project, needed by Google sign-in
/// on Android and iOS to get an ID token Firebase accepts. Optional: on
/// Android the Google Services plugin also exposes it as the
/// `default_web_client_id` resource generated from google-services.json.
const String googleServerClientId =
    String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// Google Maps key for the location picker and map previews. One flag
/// configures every platform: this constant, the Android manifest
/// (android/app/build.gradle.kts decodes the same dart-define into the
/// placeholder) and the Maps JavaScript API, which the web app loads with
/// it at runtime.
///   --dart-define=GOOGLE_MAPS_API_KEY=AIza...
/// Without it map areas show a placeholder and everything else still works.
const String googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

const bool googleMapsConfigured = googleMapsApiKey != '';

/// True when the app should fall back to mock repositories: either mocks
/// were requested explicitly, or no Supabase project is configured yet.
const bool useMockData = useMock || !supabaseConfigured;
