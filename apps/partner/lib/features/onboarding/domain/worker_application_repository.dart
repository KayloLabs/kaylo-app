import '../../profile/domain/worker_profile.dart';
import 'worker_application.dart';

abstract interface class WorkerApplicationRepository {
  Future<List<ServiceOption>> listServices();
  Future<ApplicationReceipt> submit(
    ApplicationDetails details,
    String requestToken,
  );
  Future<void> uploadDocument(
    ApplicationReceipt receipt,
    ApplicationDocumentType type,
    ApplicationDocument document,
  );
  Future<ApplicationStatus> checkStatus(String reference);
}
