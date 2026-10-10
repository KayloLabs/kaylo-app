import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../profile/domain/worker_profile.dart';
import '../domain/worker_application.dart';
import '../domain/worker_application_repository.dart';

class SupabaseWorkerApplicationRepository
    implements WorkerApplicationRepository {
  const SupabaseWorkerApplicationRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<ServiceOption>> listServices() async {
    try {
      final rows = await client
          .from('services')
          .select('service_id,service_name')
          .eq('is_active', true)
          .order('service_name');
      return rows.map(ServiceOption.fromJson).toList();
    } catch (error) {
      throw _mapError(error);
    }
  }

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
    try {
      final data = await client.rpc(
        'submit_worker_application',
        params: {
          'p_details': {
            ...details.toJson(),
            'client_request_token': requestToken,
          },
        },
      );
      return ApplicationReceipt.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } catch (error) {
      throw _mapError(error);
    }
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
    try {
      final response = await client.functions.invoke(
        'worker-application-documents',
        body: <String, String>{
          'application_id': receipt.applicationId,
          'upload_token': receipt.uploadToken,
          'doc_type': type.value,
        },
        files: [
          http.MultipartFile.fromBytes(
            'file',
            document.bytes,
            filename: '${type.value}.${document.extension}',
            contentType: http.MediaType.parse(document.mimeType!),
          ),
        ],
      );
      if (response.status != 200 ||
          response.data is! Map ||
          response.data['ok'] != true) {
        throw const WorkerApplicationFailure(
          ApplicationFailureCode.unavailable,
        );
      }
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Future<ApplicationStatus> checkStatus(String reference) async {
    try {
      final data = await client.rpc(
        'worker_application_status',
        params: {'p_reference': reference.trim().toUpperCase()},
      );
      if (data == null) {
        throw const WorkerApplicationFailure(ApplicationFailureCode.notFound);
      }
      return ApplicationStatus.fromJson(Map<String, dynamic>.from(data as Map));
    } catch (error) {
      throw _mapError(error);
    }
  }

  // Return controlled, translated UI messages. Never expose server text or
  // request bodies that can contain an applicant's personal details.
  WorkerApplicationFailure _mapError(Object error) {
    if (error is WorkerApplicationFailure) return error;
    if (error is PostgrestException) {
      if (error.code == '23505' ||
          error.message == 'APPLICATION_ALREADY_EXISTS') {
        return const WorkerApplicationFailure(
          ApplicationFailureCode.alreadyOpen,
        );
      }
      if (error.message == 'IDENTITY_ALREADY_IN_USE') {
        return const WorkerApplicationFailure(
          ApplicationFailureCode.identityInUse,
        );
      }
      if (error.code == '22023' ||
          error.message.startsWith('INVALID_') ||
          error.message == 'CONSENT_REQUIRED') {
        return const WorkerApplicationFailure(
          ApplicationFailureCode.invalidDetails,
        );
      }
      if (error.code == 'P0002') {
        return const WorkerApplicationFailure(ApplicationFailureCode.notFound);
      }
    }
    if (error is FunctionException &&
        (error.status == 401 || error.status == 403 || error.status == 409)) {
      return const WorkerApplicationFailure(
        ApplicationFailureCode.expiredUpload,
      );
    }
    if (error is FunctionException &&
        (error.status == 400 || error.status == 413)) {
      return const WorkerApplicationFailure(
        ApplicationFailureCode.invalidDocument,
      );
    }
    return const WorkerApplicationFailure(ApplicationFailureCode.connection);
  }
}
