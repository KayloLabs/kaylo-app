import 'dart:math';

import '../domain/worker_application.dart';
import '../domain/worker_application_repository.dart';

/// Holds a submission's recovery capability only for this app session. A retry
/// reuses its nonce and receipt, never creates a second application after a
/// lost response, and skips uploads already acknowledged by the server.
class ApplicationSubmission {
  ApplicationSubmission(this.repository, {this.saveReference});
  final WorkerApplicationRepository repository;
  final Future<void> Function(String reference)? saveReference;
  ApplicationReceipt? receipt;
  ApplicationStatus? completedStatus;
  ApplicationDetails? _details;
  Map<ApplicationDocumentType, ApplicationDocument>? _documents;
  String? _requestToken;
  bool _busy = false;
  final uploaded = <ApplicationDocumentType>{};

  bool get hasStarted => _requestToken != null;
  bool get isBusy => _busy;
  bool get isComplete => completedStatus != null;

  Future<ApplicationStatus> send({
    ApplicationDetails? details,
    Map<ApplicationDocumentType, ApplicationDocument>? documents,
    void Function()? onProgress,
  }) async {
    if (_busy) throw StateError('Submission already in progress');
    if (completedStatus != null) return completedStatus!;
    if (!hasStarted) {
      if (details == null ||
          !details.isValid ||
          documents == null ||
          !ApplicationDocumentType.values.every(
            (type) => documents[type]?.isValid ?? false,
          )) {
        throw const WorkerApplicationFailure(
          ApplicationFailureCode.invalidDetails,
        );
      }
      _details = details;
      _documents = Map.of(documents);
      final random = Random.secure();
      _requestToken = List.generate(
        32,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    }
    _busy = true;
    try {
      receipt ??= await repository.submit(_details!, _requestToken!);
      onProgress?.call();
      // Preferences are only a convenience for status lookup; an unavailable
      // preferences store must not prevent document upload.
      try {
        await saveReference?.call(receipt!.reference);
      } catch (_) {}
      for (final type in ApplicationDocumentType.values) {
        if (uploaded.contains(type)) continue;
        await repository.uploadDocument(receipt!, type, _documents![type]!);
        uploaded.add(type);
        onProgress?.call();
      }
      final status = await repository.checkStatus(receipt!.reference);
      if (!status.documentsComplete ||
          status.stage == WorkerApplicationStage.submitted) {
        throw const WorkerApplicationFailure(
          ApplicationFailureCode.unavailable,
        );
      }
      completedStatus = status;
      // Release all personal details and document bytes after server confirms.
      _details = null;
      _documents = null;
      _requestToken = null;
      onProgress?.call();
      return status;
    } on WorkerApplicationFailure catch (error) {
      // A definite rejection before creation is safe to edit and resubmit.
      // Ambiguous network failures retain the nonce to recover a lost reply.
      if (receipt == null &&
          {
            ApplicationFailureCode.invalidDetails,
            ApplicationFailureCode.identityInUse,
            ApplicationFailureCode.alreadyOpen,
          }.contains(error.code)) {
        _requestToken = null;
        _details = null;
        _documents = null;
      }
      rethrow;
    } finally {
      _busy = false;
    }
  }
}
