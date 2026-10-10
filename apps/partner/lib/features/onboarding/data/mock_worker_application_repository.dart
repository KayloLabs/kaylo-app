import '../../../data/mock/partner_seed.dart';
import '../../profile/domain/worker_profile.dart';
import '../domain/worker_application.dart';
import '../domain/worker_application_repository.dart';

/// Explicit sample-mode implementation. It never issues partner credentials.
class MockWorkerApplicationRepository implements WorkerApplicationRepository {
  final _receipts = <String, ApplicationReceipt>{};
  final _documents = <String, Set<ApplicationDocumentType>>{};
  final _phones = <String, String>{};

  @override
  Future<List<ServiceOption>> listServices() async =>
      PartnerSeed.serviceOptions;

  @override
  Future<ApplicationReceipt> submit(
    ApplicationDetails details,
    String requestToken,
  ) async {
    if (!details.isValid) {
      throw const WorkerApplicationFailure(
        ApplicationFailureCode.invalidDetails,
      );
    }
    if (_receipts.containsKey(requestToken)) return _receipts[requestToken]!;
    final phone = ApplicationDetails.normalizePhone(details.phone);
    if (_phones.containsKey(phone)) {
      throw const WorkerApplicationFailure(ApplicationFailureCode.alreadyOpen);
    }
    final index = _receipts.length + 1;
    final receipt = ApplicationReceipt(
      applicationId: 'sample-$index',
      reference: 'KA-DEMO-${index.toString().padLeft(6, '0')}',
      uploadToken: requestToken,
      uploadExpiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    _receipts[requestToken] = receipt;
    _phones[phone] = requestToken;
    _documents[receipt.reference] = {};
    return receipt;
  }

  @override
  Future<void> uploadDocument(
    ApplicationReceipt receipt,
    ApplicationDocumentType type,
    ApplicationDocument document,
  ) async {
    if (!document.isValid) {
      throw const WorkerApplicationFailure(
        ApplicationFailureCode.invalidDocument,
      );
    }
    _documents[receipt.reference]!.add(type);
  }

  @override
  Future<ApplicationStatus> checkStatus(String reference) async {
    final docs = _documents[reference.trim().toUpperCase()];
    if (docs == null) {
      throw const WorkerApplicationFailure(ApplicationFailureCode.notFound);
    }
    return ApplicationStatus(
      reference: reference.trim().toUpperCase(),
      stage: docs.length == 5
          ? WorkerApplicationStage.underReview
          : WorkerApplicationStage.submitted,
      documentsReceived: docs.length,
    );
  }
}
