import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/worker_application.dart';

String applicationFailureText(AppLocalizations l, Object error) {
  final code = error is WorkerApplicationFailure
      ? error.code
      : ApplicationFailureCode.connection;
  return switch (code) {
    ApplicationFailureCode.connection => l.applicationConnectionError,
    ApplicationFailureCode.identityInUse => l.applicationIdentityInUse,
    ApplicationFailureCode.alreadyOpen => l.applicationAlreadyOpen,
    ApplicationFailureCode.invalidDetails => l.applicationInvalidDetails,
    ApplicationFailureCode.invalidDocument => l.applicationInvalidDocument,
    ApplicationFailureCode.expiredUpload => l.applicationUploadExpired,
    ApplicationFailureCode.notFound => l.applicationNotFound,
    ApplicationFailureCode.unavailable => l.applicationUnavailable,
  };
}

String applicationDocumentLabel(
  AppLocalizations l,
  ApplicationDocumentType type,
) => switch (type) {
  ApplicationDocumentType.photo => l.applicationPhoto,
  ApplicationDocumentType.aadhaarFront => l.applicationAadhaarFront,
  ApplicationDocumentType.aadhaarBack => l.applicationAadhaarBack,
  ApplicationDocumentType.policeCertificate => l.documentPoliceCertificate,
  ApplicationDocumentType.selfie => l.applicationSelfie,
};
