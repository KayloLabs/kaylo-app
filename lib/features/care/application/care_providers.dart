import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_env.dart';
import '../../../core/network/supabase_providers.dart';
import '../../auth/application/current_user_provider.dart';
import '../data/mock_care_repository.dart';
import '../data/supabase_care_repository.dart';
import '../domain/care_models.dart';
import '../domain/care_repository.dart';

final careRepositoryProvider = Provider<CareRepository>((ref) {
  if (useMockData) {
    return MockCareRepository();
  }
  return SupabaseCareRepository(ref.watch(supabaseClientProvider));
});

/// Today's reminders in time order.
final medicineRemindersProvider =
    FutureProvider.autoDispose<List<MedicineReminder>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  final reminders =
      await ref.watch(careRepositoryProvider).getReminders(userId);
  return [...reminders]..sort((a, b) => a.minutesOfDay - b.minutesOfDay);
});

final emergencyContactsProvider =
    FutureProvider.autoDispose<List<EmergencyContact>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(careRepositoryProvider).getContacts(userId);
});

final sosHistoryProvider =
    FutureProvider.autoDispose<List<SosAlert>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(careRepositoryProvider).getSosHistory(userId);
});

final careControllerProvider = Provider<CareController>((ref) {
  return CareController(ref);
});

/// Writes go through here so every screen refreshes the same providers
/// after a change, instead of each one remembering what to invalidate.
class CareController {
  final Ref _ref;

  CareController(this._ref);

  CareRepository get _repo => _ref.read(careRepositoryProvider);
  String get _userId => _ref.read(currentUserIdProvider) ?? '';

  Future<void> setReminderTaken(String reminderId, bool taken) async {
    await _repo.setReminderTaken(reminderId, taken);
    _ref.invalidate(medicineRemindersProvider);
  }

  Future<void> addReminder({
    required String name,
    required String dosage,
    required int hour,
    required int minute,
  }) async {
    await _repo.addReminder(
      _userId,
      name: name,
      dosage: dosage,
      hour: hour,
      minute: minute,
    );
    _ref.invalidate(medicineRemindersProvider);
  }

  Future<void> addContact({
    required String name,
    required String relation,
    required String phone,
  }) async {
    await _repo.addContact(_userId, name: name, relation: relation, phone: phone);
    _ref.invalidate(emergencyContactsProvider);
  }

  Future<void> setPrimaryContact(String contactId) async {
    await _repo.setPrimaryContact(_userId, contactId);
    _ref.invalidate(emergencyContactsProvider);
  }

  Future<void> removeContact(String contactId) async {
    await _repo.removeContact(contactId);
    _ref.invalidate(emergencyContactsProvider);
  }

  Future<SosAlert> triggerSos({String? location}) async {
    final alert = await _repo.triggerSos(_userId, location: location);
    _ref.invalidate(sosHistoryProvider);
    return alert;
  }
}
