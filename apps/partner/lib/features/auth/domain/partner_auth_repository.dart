abstract class PartnerAuthRepository {
  Future<bool> sendOtp(String phone);
  Future<bool> verifyOtp(String phone, String code);
  Future<bool> isAuthenticated();
  Future<void> signOut();
  Stream<bool> watchAuthState();
  void dispose();
}
