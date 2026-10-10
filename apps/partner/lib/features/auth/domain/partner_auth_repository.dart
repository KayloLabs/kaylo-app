enum PartnerAccessStatus {
  signedOut,
  passwordChange,
  ready,
  registration,
  verification,
  unavailable,
}

/// An authenticated Firebase session alone never grants worker access.
class PartnerAccess {
  final PartnerAccessStatus status;
  final String? partnerId;
  final String? workerId;
  final String? verificationStatus;
  const PartnerAccess(
    this.status, {
    this.partnerId,
    this.workerId,
    this.verificationStatus,
  });

  bool get signedIn => status != PartnerAccessStatus.signedOut;
  bool get canWork => status == PartnerAccessStatus.ready;

  @override
  bool operator ==(Object other) =>
      other is PartnerAccess &&
      other.status == status &&
      other.partnerId == partnerId &&
      other.workerId == workerId &&
      other.verificationStatus == verificationStatus;
  @override
  int get hashCode =>
      Object.hash(status, partnerId, workerId, verificationStatus);
}

enum PartnerAuthError {
  invalidId,
  invalidCredentials,
  tooManyAttempts,
  network,
  unavailable,
  weakPassword,
  differentPassword,
  sessionExpired,
  passwordConfirmation,
  identityNotAllowed,
}

class PartnerAuthException implements Exception {
  final PartnerAuthError code;
  const PartnerAuthException(this.code);
}

String? normalizePartnerId(String value) {
  final id = value.trim().toUpperCase();
  return RegExp(r'^KP-[0-9]{6}$').hasMatch(id) ? id : null;
}

String partnerEmail(String partnerId) {
  final id = normalizePartnerId(partnerId);
  if (id == null) throw const PartnerAuthException(PartnerAuthError.invalidId);
  return '${id.toLowerCase()}@partners.kaylo.app';
}

abstract class PartnerAuthRepository {
  Future<PartnerAccess> signIn(String partnerId, String password);
  Future<PartnerAccess> changePassword(String password);
  Future<PartnerAccess> checkAccess();
  Future<bool> isAuthenticated();
  Future<void> signOut();
  Stream<PartnerAccess> watchAccess();
  void dispose();
}
