import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/partner_auth_repository.dart';

typedef SendPartnerReset =
    Future<void> Function(String partnerId, String email);

final sendPartnerResetProvider = Provider<SendPartnerReset>((ref) {
  return (partnerId, email) async {
    if (useMockData) throw const PartnerResetDemoException();
    if (!supabaseConfigured) {
      throw const PartnerAuthException(PartnerAuthError.unavailable);
    }
    try {
      final response = await Supabase.instance.client.functions
          .invoke(
            'partner-password-reset',
            body: {'partner_id': partnerId, 'email': email},
          )
          .timeout(const Duration(seconds: 30));
      if (response.data is! Map || response.data['ok'] != true) {
        throw const PartnerAuthException(PartnerAuthError.unavailable);
      }
    } on FunctionException catch (error) {
      throw PartnerAuthException(
        error.status == 429
            ? PartnerAuthError.tooManyAttempts
            : PartnerAuthError.unavailable,
      );
    }
  };
});

class PartnerResetDemoException implements Exception {
  const PartnerResetDemoException();
}
