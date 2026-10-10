import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kaylo_partner/features/onboarding/application/application_submission.dart';
import 'package:kaylo_partner/features/onboarding/data/mock_worker_application_repository.dart';
import 'package:kaylo_partner/features/onboarding/data/supabase_worker_application_repository.dart';
import 'package:kaylo_partner/features/onboarding/domain/worker_application.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const details = ApplicationDetails(
  fullName: 'Test Applicant',
  phone: '9847012345',
  email: 'applicant@example.test',
  profession: 'Electrician',
  services: ['svc-electrical'],
  experienceYears: 3,
  district: 'Kannur',
  travelRadiusKm: 15,
  upiId: 'test@bank',
  consent: true,
);
ApplicationDocument photo() => ApplicationDocument(
  name: 'private-name.jpg',
  bytes: Uint8List.fromList([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x00, 0xff, 0xd9]),
);
Map<ApplicationDocumentType, ApplicationDocument> documents() => {
  for (final type in ApplicationDocumentType.values) type: photo(),
};

class InterruptedRepository extends MockWorkerApplicationRepository {
  final submits = <String>[];
  final uploads = <ApplicationDocumentType>[];
  bool loseFirstReply = false;
  bool rejectDetails = false;
  bool failNextUpload = true;
  @override
  Future<ApplicationReceipt> submit(
    ApplicationDetails details,
    String requestToken,
  ) async {
    submits.add(requestToken);
    if (rejectDetails) {
      rejectDetails = false;
      throw const WorkerApplicationFailure(
        ApplicationFailureCode.invalidDetails,
      );
    }
    final receipt = await super.submit(details, requestToken);
    if (loseFirstReply) {
      loseFirstReply = false;
      throw const WorkerApplicationFailure(ApplicationFailureCode.connection);
    }
    return receipt;
  }

  @override
  Future<void> uploadDocument(
    ApplicationReceipt receipt,
    ApplicationDocumentType type,
    ApplicationDocument document,
  ) async {
    uploads.add(type);
    if (type == ApplicationDocumentType.aadhaarBack && failNextUpload) {
      failNextUpload = false;
      throw const WorkerApplicationFailure(ApplicationFailureCode.connection);
    }
    return super.uploadDocument(receipt, type, document);
  }
}

void main() {
  test('normalizes local phone and requires real delivery email', () {
    expect(details.isValid, isTrue);
    expect(details.toJson()['phone'], '+919847012345');
    expect(ApplicationDetails.validPhone('123'), isFalse);
    expect(ApplicationDetails.validPhone('+91 98470 12345'), isTrue);
    expect(ApplicationDetails.validEmail('broken@'), isFalse);
    expect(
      ApplicationDetails.validEmail('kp-000001@partners.kaylo.app'),
      isFalse,
    );
  });

  test('bank payout requires holder, bank, account and IFSC', () {
    expect(
      const ApplicationBankAccount(
        holder: 'Test Applicant',
        bankName: 'Test Bank',
        accountNumber: '12345678901',
        ifsc: 'SBIN0001234',
      ).isValid,
      isTrue,
    );
    expect(
      const ApplicationBankAccount(
        holder: '',
        bankName: 'Test Bank',
        accountNumber: '12345678901',
        ifsc: 'SBIN0001234',
      ).isValid,
      isFalse,
    );
    expect(
      const ApplicationBankAccount(
        holder: 'Test Applicant',
        bankName: 'Test Bank',
        accountNumber: '12345678901',
        ifsc: 'invalid',
      ).isValid,
      isFalse,
    );
  });

  test(
    'document MIME comes from bytes and oversized or disguised files fail',
    () {
      expect(photo().mimeType, 'image/jpeg');
      expect(
        ApplicationDocument(
          name: 'photo.jpg',
          bytes: Uint8List.fromList('plain text'.codeUnits),
        ).isValid,
        isFalse,
      );
      expect(
        ApplicationDocument(
          name: 'police.pdf',
          bytes: Uint8List.fromList('%PDF-1.7'.codeUnits),
        ).mimeType,
        'application/pdf',
      );
      final huge = Uint8List(ApplicationDocument.maxBytes + 1)
        ..setAll(0, [0xff, 0xd8, 0xff]);
      expect(
        ApplicationDocument(name: 'big.jpg', bytes: huge).isValid,
        isFalse,
      );
    },
  );

  test(
    'five documents are required before creation, not after claiming success',
    () async {
      final repository = InterruptedRepository();
      final submission = ApplicationSubmission(repository);
      final incomplete = documents()..remove(ApplicationDocumentType.selfie);
      await expectLater(
        submission.send(details: details, documents: incomplete),
        throwsA(isA<WorkerApplicationFailure>()),
      );
      expect(repository.submits, isEmpty);
      expect(submission.receipt, isNull);
    },
  );

  test(
    'retry resumes missing uploads using same application and persists only reference',
    () async {
      final repository = InterruptedRepository();
      final saved = <String>[];
      final submission = ApplicationSubmission(
        repository,
        saveReference: (ref) async {
          saved.add(ref);
        },
      );
      await expectLater(
        submission.send(details: details, documents: documents()),
        throwsA(isA<WorkerApplicationFailure>()),
      );
      final reference = submission.receipt!.reference;
      expect(submission.uploaded.length, 2);
      expect(submission.isComplete, isFalse);
      final incomplete = await repository.checkStatus(reference);
      expect(incomplete.stage, WorkerApplicationStage.submitted);
      final status = await submission.send();
      expect(status.reference, reference);
      expect(status.stage, WorkerApplicationStage.underReview);
      expect(repository.submits.length, 1);
      expect(
        repository.uploads
            .where((type) => type == ApplicationDocumentType.photo)
            .length,
        1,
      );
      expect(
        repository.uploads
            .where((type) => type == ApplicationDocumentType.aadhaarBack)
            .length,
        2,
      );
      expect(saved, everyElement(reference));
      expect(submission.isComplete, isTrue);
    },
  );

  test(
    'lost submission reply recovers with cryptographic nonce without duplicate application',
    () async {
      final repository = InterruptedRepository()
        ..loseFirstReply = true
        ..failNextUpload = false;
      final submission = ApplicationSubmission(repository);
      await expectLater(
        submission.send(details: details, documents: documents()),
        throwsA(isA<WorkerApplicationFailure>()),
      );
      expect(submission.receipt, isNull);
      expect(submission.hasStarted, isTrue);
      final status = await submission.send();
      expect(status.documentsComplete, isTrue);
      expect(repository.submits.length, 2);
      expect(repository.submits.first, repository.submits.last);
      expect(repository.submits.first, matches(RegExp(r'^[0-9a-f]{64}$')));
    },
  );

  test(
    'definite validation rejection permits correction before another submit',
    () async {
      final repository = InterruptedRepository()
        ..rejectDetails = true
        ..failNextUpload = false;
      final submission = ApplicationSubmission(repository);
      await expectLater(
        submission.send(details: details, documents: documents()),
        throwsA(isA<WorkerApplicationFailure>()),
      );
      expect(submission.hasStarted, isFalse);
      expect(submission.receipt, isNull);
      final status = await submission.send(
        details: details,
        documents: documents(),
      );
      expect(status.stage, WorkerApplicationStage.underReview);
      expect(repository.submits.first, isNot(repository.submits.last));
    },
  );

  test(
    'multipart upload sends actual MIME and capabilities only to document endpoint',
    () async {
      late http.Request captured;
      final client = SupabaseClient(
        'https://kaylo.example.test',
        'public-test-key',
        httpClient: MockClient((request) async {
          captured = request;
          return http.Response(
            '{"ok":true,"doc_type":"photo"}',
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = SupabaseWorkerApplicationRepository(client);
      await repo.uploadDocument(
        ApplicationReceipt(
          applicationId: 'abc123',
          reference: 'KA-REFERENCE',
          uploadToken: 'capability',
          uploadExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        ),
        ApplicationDocumentType.photo,
        photo(),
      );
      expect(captured.url.path, '/functions/v1/worker-application-documents');
      expect(
        captured.headers['content-type'],
        startsWith('multipart/form-data; boundary='),
      );
      final body = latin1.decode(captured.bodyBytes);
      expect(body, contains('content-type: image/jpeg'));
      expect(body, contains('filename="photo.jpg"'));
      expect(body, isNot(contains('private-name')));
      expect(body, contains('name="upload_token"'));
      expect(body, contains('name="application_id"'));
    },
  );

  for (final entry in {
    'APPLICATION_ALREADY_EXISTS': ApplicationFailureCode.alreadyOpen,
    'IDENTITY_ALREADY_IN_USE': ApplicationFailureCode.identityInUse,
    'INVALID_SERVICES': ApplicationFailureCode.invalidDetails,
    'CONSENT_REQUIRED': ApplicationFailureCode.invalidDetails,
  }.entries) {
    test('maps ${entry.key} without exposing server details', () async {
      final client = SupabaseClient(
        'https://kaylo.example.test',
        'public-test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({'code': 'P0001', 'message': entry.key}),
            400,
            request: request,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      addTearDown(client.dispose);
      await expectLater(
        SupabaseWorkerApplicationRepository(client).submit(details, 'a' * 64),
        throwsA(
          isA<WorkerApplicationFailure>().having(
            (e) => e.code,
            'code',
            entry.value,
          ),
        ),
      );
    });
  }
}
