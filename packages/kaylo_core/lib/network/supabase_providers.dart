import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_env.dart';
import 'app_failure.dart';

/// The shared Supabase client. Only valid when [supabaseConfigured] is true
/// and `Supabase.initialize` ran in main.dart.
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  if (!supabaseConfigured) {
    throw StateError(
      'Supabase is not configured. Pass --dart-define=SUPABASE_URL and '
      '--dart-define=SUPABASE_ANON_KEY, or run with --dart-define=USE_MOCK=true.',
    );
  }
  return Supabase.instance.client;
});

/// Maps Supabase/PostgREST errors onto the app's failure types so the UI
/// layer never needs to know which backend threw.
AppFailure mapSupabaseError(Object error) {
  if (error is AppFailure) return error;
  if (error is PostgrestException) {
    return ServerFailure(error.message, code: error.code, originalError: error);
  }
  if (error is AuthException) {
    return ServerFailure(error.message, code: error.code, originalError: error);
  }
  return NetworkFailure(
    'Could not reach the server. Check your connection.',
    code: 'network',
    originalError: error,
  );
}
