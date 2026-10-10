/// Sign-in for workers. The sample build accepts any number with code
/// 1234; the live build is Firebase Authentication, and a sign-in that
/// fails throws a [PartnerAuthMessage] the screen can show as it is.
abstract class PartnerAuthRepository {
  Future<bool> sendOtp(String phone);
  Future<bool> verifyOtp(String phone, String code);
  Future<void> signInWithGoogle();
  Future<bool> isAuthenticated();
  Future<void> signOut();
  Stream<bool> watchAuthState();
  void dispose();
}

class PartnerAuthMessage implements Exception {
  final String message;
  PartnerAuthMessage(this.message);

  @override
  String toString() => message;
}
