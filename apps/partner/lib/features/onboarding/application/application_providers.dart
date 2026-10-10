import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaylo_core/config/app_env.dart';
import 'package:kaylo_core/network/supabase_providers.dart';
import 'package:kaylo_core/services/storage_service.dart';

import '../../profile/domain/worker_profile.dart';
import '../data/mock_worker_application_repository.dart';
import '../data/supabase_worker_application_repository.dart';
import '../domain/worker_application_repository.dart';
import '../domain/worker_application.dart';
import 'application_submission.dart';

const applicationReferencePreferenceKey = 'kaylo_partner_application_reference';

final workerApplicationRepositoryProvider = Provider<WorkerApplicationRepository>((
  ref,
) {
  // Real application data must never silently fall back to a sample repository
  // when Firebase or Supabase is unavailable. Applying needs no Firebase user.
  if (useMock) return MockWorkerApplicationRepository();
  if (!supabaseConfigured) return const _UnavailableApplicationRepository();
  return SupabaseWorkerApplicationRepository(ref.watch(supabaseClientProvider));
});

final applicationServicesProvider = FutureProvider<List<ServiceOption>>(
  (ref) => ref.watch(workerApplicationRepositoryProvider).listServices(),
);

final applicationSubmissionProvider = Provider<ApplicationSubmission>(
  (ref) => ApplicationSubmission(
    ref.watch(workerApplicationRepositoryProvider),
    saveReference: (reference) async {
      await ref
          .read(sharedPreferencesProvider)
          .setString(applicationReferencePreferenceKey, reference);
    },
  ),
);

class _UnavailableApplicationRepository implements WorkerApplicationRepository {
  const _UnavailableApplicationRepository();
  Never _unavailable() =>
      throw const WorkerApplicationFailure(ApplicationFailureCode.unavailable);
  @override
  Future<List<ServiceOption>> listServices() async => _unavailable();
  @override
  Future<ApplicationReceipt> submit(
    ApplicationDetails details,
    String requestToken,
  ) async => _unavailable();
  @override
  Future<void> uploadDocument(
    ApplicationReceipt receipt,
    ApplicationDocumentType type,
    ApplicationDocument document,
  ) async => _unavailable();
  @override
  Future<ApplicationStatus> checkStatus(String reference) async =>
      _unavailable();
}
