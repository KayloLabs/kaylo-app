abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getToken();
}

// M4 will implement FCM logic here in R2.
class NotificationServiceStub implements NotificationService {
  @override
  Future<void> initialize() async {
    // Stub
  }

  @override
  Future<String?> getToken() async {
    // Stub
    return 'dummy-fcm-token';
  }
}
