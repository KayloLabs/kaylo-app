import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/partner_auth_repository.dart';

String partnerAuthMessage(AppLocalizations l10n, Object error) {
  final code = error is PartnerAuthException
      ? error.code
      : PartnerAuthError.unavailable;
  return switch (code) {
    PartnerAuthError.invalidId => l10n.authInvalidId,
    PartnerAuthError.invalidCredentials => l10n.authInvalidCredentials,
    PartnerAuthError.tooManyAttempts => l10n.authTooManyAttempts,
    PartnerAuthError.network => l10n.authNetworkError,
    PartnerAuthError.unavailable => l10n.authUnavailable,
    PartnerAuthError.weakPassword => l10n.authPasswordRule,
    PartnerAuthError.differentPassword => l10n.authDifferentPassword,
    PartnerAuthError.sessionExpired => l10n.authSessionExpired,
    PartnerAuthError.passwordConfirmation => l10n.authPasswordConfirmation,
    PartnerAuthError.identityNotAllowed => l10n.authIdentityNotAllowed,
  };
}
